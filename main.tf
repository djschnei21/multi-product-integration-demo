terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.6"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.66.0"
    }
  }
}

provider "doormat" {}

provider "hcp" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::365006510262:role/tfc-doormat-role"
}

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

resource "hcp_hvn" "main" {
  hvn_id         = "${var.stack_id}-hvn"
  cloud_provider = "aws"
  region         = var.hvn_region
  cidr_block     = var.hvn_cidr_block
}

module "aws_hcp_network_config" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.12.1"

  hvn             = hcp_hvn.main
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  route_table_ids = module.vpc.public_route_table_ids
}

resource "hcp_vault_cluster" "hashistack" {
  cluster_id      = "${var.stack_id}-vault-cluster"
  hvn_id          = hcp_hvn.main.hvn_id
  tier            = var.vault_cluster_tier
  public_endpoint = true
}

resource "hcp_consul_cluster" "hashistack" {
  cluster_id      = "${var.stack_id}-consul-cluster"
  hvn_id          = hcp_hvn.main.hvn_id
  tier            = var.consul_cluster_tier
  public_endpoint = true
  connect_enabled = true
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.hashistack.cluster_id
}

resource "hcp_boundary_cluster" "hashistack" {
  cluster_id = "${var.stack_id}-boundary-cluster"
  tier       = var.boundary_cluster_tier
  username   = var.boundary_admin_username
  password   = var.boundary_admin_password
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
    cidr_blocks = ["0.0.0.0/0"]
  }

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

data "hcp_packer_image" "ubuntu_lunar_hashi_amd" {
  bucket_name    = "ubuntu-lunar-hashi"
  component_type = "amazon-ebs.amd"
  channel        = "latest"
  cloud_provider = "aws"
  region         = "us-east-2"
}

data "hcp_packer_image" "ubuntu_lunar_hashi_arm" {
  bucket_name    = "ubuntu-lunar-hashi"
  component_type = "amazon-ebs.arm"
  channel        = "latest"
  cloud_provider = "aws"
  region         = "us-east-2"
}

resource "aws_launch_template" "nomad_server_asg_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_image.ubuntu_lunar_hashi_amd.cloud_image_id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ aws_security_group.nomad_server.id ]
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-server.tpl",
      {
        nomad_license      = var.nomad_license,
        consul_ca_file     = hcp_consul_cluster.hashistack.consul_ca_file,
        consul_config_file = hcp_consul_cluster.hashistack.consul_config_file
        consul_acl_token   = hcp_consul_cluster_root_token.token.secret_id
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
  health_check_type = "EC2"
  health_check_grace_period = "60"

  name_prefix = "nomad-server"

  launch_template {
    id = aws_launch_template.nomad_server_asg_template.id
    version = aws_launch_template.nomad_server_asg_template.latest_version
  }
  
  vpc_zone_identifier = module.vpc.public_subnets

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