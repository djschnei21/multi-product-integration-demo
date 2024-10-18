data "hcp_vault_secrets_secret" "nomad_license" {
  app_name    = "hashistack"
  secret_name = "nomad_license"
}

resource "vault_jwt_auth_backend" "nomad" {
  description        = "JWT for Nomad Workload Identity"
  path               = "nomad"
  jwks_url           = "http://${aws_alb.nomad.dns_name}/.well-known/jwks.json"
  jwt_supported_algs = ["RS256", "EdDSA"]
  default_role       = "nomad-workloads"
}

resource "vault_jwt_auth_backend_role" "nomad_workloads_role" {
  backend        = vault_jwt_auth_backend.nomad.path
  role_name      = "nomad-workloads"
  token_policies = ["nomad-workloads"]

  bound_audiences = ["vault.io"]
  bound_claims = {
    nomad_namespace = "default"
  }

  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id    = "nomad_job_id"
    nomad_task      = "nomad_task"
  }

  user_claim              = "/nomad_job_id"
  user_claim_json_pointer = true
  role_type               = "jwt"
}

resource "vault_policy" "nomad_workloads_policy" {
  name = "nomad-workloads"
  policy = templatefile("${path.module}/nomad-workloads-policy.hcl.tpl",
    {
      accessor = vault_jwt_auth_backend.nomad.accessor
    }
  )
}

resource "vault_mount" "ssh" {
  path = "ssh"
  type = "ssh"
}

resource "vault_ssh_secret_backend_ca" "ssh_ca" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh_role" {
  name                    = "boundary_role"
  backend                 = vault_mount.ssh.path
  key_type                = "ca"
  allow_user_certificates = true
  default_user            = "ubuntu"
  allowed_users           = "*"

  default_extensions = {
    "permit-pty" = ""
  }

  allowed_extensions = "*"
}

resource "aws_security_group" "nomad-cluster" {
  name   = "nomad-server"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 4646
    to_port         = 4646
    protocol        = "tcp"
    security_groups = [aws_security_group.nomad_lb.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "nomad" {
  name   = "nomad"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true # reference to the security group itself
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "nomad_lb" {
  name        = "nomad_lb_sg"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }
}

resource "aws_alb" "nomad" {
  name            = "nomad-alb"
  security_groups = [aws_security_group.nomad_lb.id]
  subnets         = var.subnet_ids
}

resource "aws_alb_target_group" "nomad" {
  name     = "nomad"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/v1/agent/health?type=server"
    port = "4646"
  }
}

resource "aws_alb_listener" "nomad" {
  load_balancer_arn = aws_alb.nomad.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.nomad.arn
  }
}

data "hcp_packer_artifact" "ubuntu_lunar_hashi_amd" {
  bucket_name    = "ubuntu-mantic-hashi"
  component_type = "amazon-ebs.amd"
  channel_name   = "latest"
  platform       = "aws"
  region         = var.region
}

data "hcp_packer_artifact" "ubuntu_lunar_hashi_arm" {
  bucket_name    = "ubuntu-mantic-hashi"
  component_type = "amazon-ebs.arm"
  channel_name   = "latest"
  platform       = "aws"
  region         = var.region
}

resource "aws_launch_template" "nomad-cluster_launch_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_artifact.ubuntu_lunar_hashi_amd.external_identifier
  instance_type = "t3a.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.nomad-cluster.id,
      aws_security_group.nomad.id,
      var.hvn_sg_id
    ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-server.tpl",
      {
        nomad_license      = data.hcp_vault_secrets_secret.nomad_license.secret_value,
        consul_ca_file     = var.consul_ca_file,
        consul_config_file = var.consul_config_file,
        consul_acl_token   = var.consul_root_token,
        vault_ssh_pub_key  = vault_ssh_secret_backend_ca.ssh_ca.public_key
      }
    )
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nomad-cluster_asg" {
  desired_capacity          = 3
  max_size                  = 5
  min_size                  = 1
  health_check_type         = "ELB"
  health_check_grace_period = "60"

  name = "nomad-server"

  launch_template {
    id      = aws_launch_template.nomad-cluster_launch_template.id
    version = aws_launch_template.nomad-cluster_launch_template.latest_version
  }

  vpc_zone_identifier = var.subnet_ids

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.nomad-cluster_asg.id
  lb_target_group_arn    = aws_alb_target_group.nomad.arn
}

data "http" "bootstrap" {
  depends_on = [aws_autoscaling_attachment.asg_attachment]
  url        = "http://${aws_alb.nomad.dns_name}/v1/acl/bootstrap"
  method     = "POST"
  insecure   = true

  retry {
    attempts = 10
    max_delay_ms = 15000
    min_delay_ms = 10000
  }
}

locals {
  nomad_bootstrap = jsondecode(data.http.bootstrap.response_body)
  SecretID = local.nomad_bootstrap.SecretID
}

resource "hcp_vault_secrets_secret" "bootstrap" {
  lifecycle {
    ignore_changes = [secret_value]
    replace_triggered_by = [resource.aws_autoscaling_group.nomad-cluster_asg]
  }
  app_name      = "hashistack"
  secret_name   = "nomad_bootstrap_secret_id"
  secret_value  = local.SecretID
}