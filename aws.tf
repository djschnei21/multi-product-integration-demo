provider "aws" {
  region     = var.aws_region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  azs                  = data.aws_availability_zones.available.names
  cidr                 = var.vpc_cidr_block
  enable_dns_hostnames = true
  name                 = "${var.stack_id}-vpc"
  private_subnets      = var.vpc_private_subnets
  public_subnets       = var.vpc_public_subnets
}

resource "aws_security_group" "nomad_server" {
  name   = "nomad-server"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    security_groups = [aws_security_group.nomad_lb.id]
  }

  # ingress {
  #   from_port   = 4646
  #   to_port     = 4646
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true  # reference to the security group itself
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
  vpc_id = module.vpc.vpc_id

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
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }
}

resource "aws_alb" "nomad" {
  name               = "nomad-alb"
  security_groups    = [ aws_security_group.nomad_lb.id ]
  subnets            = module.vpc.public_subnets
}

resource "aws_alb_target_group" "nomad" {
  name     = "nomad"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

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

resource "aws_launch_template" "nomad_server_asg_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_image.ubuntu_lunar_hashi_amd.cloud_image_id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [ aws_security_group.nomad_server.id ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-server.tpl",
      {
        nomad_license      = var.nomad_license,
        consul_ca_file     = hcp_consul_cluster.hashistack.consul_ca_file,
        consul_config_file = hcp_consul_cluster.hashistack.consul_config_file
        consul_acl_token   = data.consul_acl_token_secret_id.read.secret_id
      }
    )
  )

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_autoscaling_group" "nomad_server_asg" {
#   desired_capacity  = 3
#   max_size          = 5
#   min_size          = 1
#   health_check_type = "ELB"
#   health_check_grace_period = "60"

#   name = "nomad-server"

#   launch_template {
#     id = aws_launch_template.nomad_server_asg_template.id
#     version = aws_launch_template.nomad_server_asg_template.latest_version
#   }
  
#   vpc_zone_identifier = module.vpc.public_subnets

#   instance_refresh {
#     strategy = "Rolling"
#     preferences {
#       min_healthy_percentage = 50
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_attachment" "asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.nomad_server_asg.id
#   lb_target_group_arn   = aws_alb_target_group.nomad.arn
# }

# resource "null_resource" "bootstrap_acl" {
#   triggers = {
#     asg = aws_autoscaling_group.nomad_server_asg.id
#   }
#   depends_on = [ vault_mount.kvv2 ]
#   provisioner "local-exec" {
#     command = <<EOF
#       sleep 60  # wait for the instances in ASG to be up and running
#       MAX_RETRIES=5
#       COUNT=0
#       while [ $COUNT -lt $MAX_RETRIES ]; do
#         RESPONSE=$(curl --write-out %%{http_code} --silent --output /dev/null http://${aws_alb.nomad.dns_name}/v1/agent/health?type=server)
#         if [ $RESPONSE -eq 200 ]; then
#           curl --request POST http://${aws_alb.nomad.dns_name}/v1/acl/bootstrap >> nomad_bootstrap.json
#           JSON_DATA=$(jq -c . < nomad_bootstrap.json)
#           for key in $(echo $JSON_DATA | jq -r 'keys[]'); do
#               value=$(echo $JSON_DATA | jq -r --arg key "$key" '.[$key]')
#               curl --header "X-Vault-Token: ${hcp_vault_cluster_admin_token.provider.token}" \
#                   --header "X-Vault-Namespace: admin" \
#                   --request PUT \
#                   --data "{ \"data\": { \"$key\": $value }}" \
#                   ${hcp_vault_cluster.hashistack.vault_public_endpoint_url}/v1/hashistack-admin/data/nomad_bootstrap/$key
#           done
#           break
#         fi
#         COUNT=$((COUNT + 1))
#         sleep 10
#       done
#     EOF
#   }
# }