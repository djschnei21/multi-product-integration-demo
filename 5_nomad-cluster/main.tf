terraform {
  required_providers {
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.6"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }
}

provider "doormat" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/tfc-doormat-role_5_nomad-cluster"
}

provider "aws" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "terraform_remote_state" "networking" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "1_networking"
    }
  }
}

data "terraform_remote_state" "hcp_clusters" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "2_hcp-clusters"
    }
  }
}

provider "vault" {}

resource "vault_policy" "nomad_policy" {
  name   = "nomad"
  policy = file("nomad-server-policy.hcl")
}

resource "vault_token_auth_backend_role" "nomad_role" {
  role_name = "nomad_role"
  allowed_policies  = [vault_policy.nomad_policy.name]
  orphan = true
  token_explicit_max_ttl = "0"
  token_period  = "259200"
  renewable = true
}

resource "vault_token" "nomad_token" {
  role_name   = vault_token_auth_backend_role.nomad_role.role_name
  policies    = [vault_policy.nomad_policy.name]
}

resource "vault_mount" "ssh" {
  path = "ssh"
  type = "ssh"
}

resource "vault_ssh_secret_backend_ca" "ssh_ca" {
  backend               = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh_role" {
  name                   = "boundary_role"
  backend                = vault_mount.ssh.path
  key_type                = "ca"
  allow_user_certificates = true
  default_user            = "ubuntu"
  allowed_users           = "*"
  
  default_extensions = {
    "permit-pty" = ""
  }
  
  allowed_extensions = "*"
}

resource "aws_security_group" "nomad_server" {
  name   = "nomad-server"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    security_groups = [ aws_security_group.nomad_lb.id ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "nomad" {
  name   = "nomad"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true  # reference to the security group itself
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
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

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
    cidr_blocks = data.terraform_remote_state.networking.outputs.subnet_cidrs
  }
}

resource "aws_alb" "nomad" {
  name               = "nomad-alb"
  security_groups    = [ aws_security_group.nomad_lb.id ]
  subnets            = data.terraform_remote_state.networking.outputs.subnet_ids
}

resource "aws_alb_target_group" "nomad" {
  name     = "nomad"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.networking.outputs.vpc_id

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

data "hcp_packer_image" "ubuntu_lunar_hashi_amd" {
  bucket_name    = "ubuntu-mantic-hashi"
  component_type = "amazon-ebs.amd"
  channel        = "latest"
  cloud_provider = "aws"
  region         = var.region
}

data "hcp_packer_image" "ubuntu_lunar_hashi_arm" {
  bucket_name    = "ubuntu-mantic-hashi"
  component_type = "amazon-ebs.arm"
  channel        = "latest"
  cloud_provider = "aws"
  region         = var.region
}

resource "aws_launch_template" "nomad_server_launch_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_image.ubuntu_lunar_hashi_amd.cloud_image_id
  instance_type = "t3a.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ 
      aws_security_group.nomad_server.id,
      aws_security_group.nomad.id,
      data.terraform_remote_state.networking.outputs.hvn_sg_id
    ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-server.tpl",
      {
        nomad_license      = var.nomad_license,
        nomad_token        = vault_token.nomad_token.client_token
        consul_ca_file     = data.terraform_remote_state.hcp_clusters.outputs.consul_ca_file,
        consul_config_file = data.terraform_remote_state.hcp_clusters.outputs.consul_config_file,
        consul_acl_token   = data.terraform_remote_state.hcp_clusters.outputs.consul_root_token,
        vault_ssh_pub_key  = vault_ssh_secret_backend_ca.ssh_ca.public_key,
        vault_public_endpoint = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
      }
    )
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nomad_server_asg" {
  desired_capacity  = 3
  max_size          = 5
  min_size          = 1
  health_check_type = "ELB"
  health_check_grace_period = "60"

  name = "nomad-server"

  launch_template {
    id = aws_launch_template.nomad_server_launch_template.id
    version = aws_launch_template.nomad_server_launch_template.latest_version
  }
  
  vpc_zone_identifier = data.terraform_remote_state.networking.outputs.subnet_ids

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
  autoscaling_group_name = aws_autoscaling_group.nomad_server_asg.id
  lb_target_group_arn   = aws_alb_target_group.nomad.arn
}

resource "vault_mount" "kvv2" {
  path        = "hashistack-admin"
  type        = "kv"
  options     = { version = "2" }
}

resource "null_resource" "bootstrap_acl" {
  triggers = {
    asg = aws_autoscaling_group.nomad_server_asg.id
  }
  depends_on = [ vault_mount.kvv2 ]
  provisioner "local-exec" {
    command = <<EOF
    sleep 60  # wait for the instances in ASG to be up and running
    MAX_RETRIES=10
    COUNT=0
    while [ $COUNT -lt $MAX_RETRIES ]; do
      RESPONSE=$(curl --write-out %%{http_code} --silent --output /dev/null http://${aws_alb.nomad.dns_name}/v1/agent/health?type=server)
      if [ $RESPONSE -eq 200 ]; then
        curl --request POST http://${aws_alb.nomad.dns_name}/v1/acl/bootstrap >> nomad_bootstrap.json
        JSON_DATA=$(jq -c . < nomad_bootstrap.json)
        for key in $(echo $JSON_DATA | jq -r 'keys[]'); do
            value=$(echo $JSON_DATA | jq -r --arg key "$key" '.[$key] | @uri')
            curl --header "X-Vault-Token: ${data.terraform_remote_state.hcp_clusters.outputs.vault_root_token}" \
                --header "X-Vault-Namespace: admin" \
                --request PUT \
                --data "{ \"data\": { \"$key\": \"$value\" }}" \
                ${data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint}/v1/hashistack-admin/data/nomad_bootstrap/$key
        done
        break
      fi
      COUNT=$((COUNT + 1))
      sleep 10
    done
    EOF
  }
}