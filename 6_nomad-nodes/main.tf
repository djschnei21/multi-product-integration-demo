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

    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.66.0"
    }

    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    nomad = {
      source = "hashicorp/nomad"
      version = "2.0.0-beta.1"
    }
  }
}

provider "doormat" {}

provider "hcp" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/tfc-doormat-role_6_nomad-nodes"
}

provider "aws" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

provider "vault" {}

data "vault_kv_secret_v2" "bootstrap" {
  mount = data.terraform_remote_state.nomad_cluster.outputs.bootstrap_kv
  name  = "nomad_bootstrap/SecretID"
}

provider "nomad" {
  address = data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint
  secret_id = data.vault_kv_secret_v2.bootstrap.data["SecretID"]
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

data "terraform_remote_state" "nomad_cluster" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "5_nomad-cluster"
    }
  }
}

data "hcp_packer_image" "ubuntu_lunar_hashi_x86" {
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

resource "aws_iam_role" "efs_role" {
  name = "efs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "efs_policy" {
  name = "efs-policy"
  role = aws_iam_role.efs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "elasticfilesystem:*"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "efs_instance_profile" {
  name = "efs-instance-profile"
  role = aws_iam_role.efs_role.name
}


resource "aws_launch_template" "nomad_client_x86_launch_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_image.ubuntu_lunar_hashi_x86.cloud_image_id
  instance_type = "t3a.medium"

  iam_instance_profile {
    arn = aws_iam_instance_profile.efs_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ 
      data.terraform_remote_state.nomad_cluster.outputs.nomad_sg,
      data.terraform_remote_state.networking.outputs.hvn_sg_id
    ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-node.tpl",
      {
        nomad_license      = var.nomad_license,
        consul_ca_file     = data.terraform_remote_state.hcp_clusters.outputs.consul_ca_file,
        consul_config_file = data.terraform_remote_state.hcp_clusters.outputs.consul_config_file,
        consul_acl_token   = data.terraform_remote_state.hcp_clusters.outputs.consul_root_token,
        node_pool          = "x86",
        vault_ssh_pub_key  = data.terraform_remote_state.nomad_cluster.outputs.ssh_ca_pub_key,
        vault_public_endpoint = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
      }
    )
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nomad_client_x86_asg" {
  desired_capacity  = 2
  max_size          = 2
  min_size          = 1
  health_check_type = "EC2"
  health_check_grace_period = "60"

  name = "nomad-client-x86"

  launch_template {
    id = aws_launch_template.nomad_client_x86_launch_template.id
    version = aws_launch_template.nomad_client_x86_launch_template.latest_version
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

resource "aws_launch_template" "nomad_client_arm_launch_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_image.ubuntu_lunar_hashi_arm.cloud_image_id
  instance_type = "t4g.medium"

  iam_instance_profile {
    arn = aws_iam_instance_profile.efs_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ 
      data.terraform_remote_state.nomad_cluster.outputs.nomad_sg,
      data.terraform_remote_state.networking.outputs.hvn_sg_id
    ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-node.tpl",
      {
        nomad_license      = var.nomad_license,
        consul_ca_file     = data.terraform_remote_state.hcp_clusters.outputs.consul_ca_file,
        consul_config_file = data.terraform_remote_state.hcp_clusters.outputs.consul_config_file,
        consul_acl_token   = data.terraform_remote_state.hcp_clusters.outputs.consul_root_token,
        node_pool          = "arm",
        vault_ssh_pub_key  = data.terraform_remote_state.nomad_cluster.outputs.ssh_ca_pub_key,
        vault_public_endpoint = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
      }
    )
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nomad_client_arm_asg" {
  desired_capacity  = 2
  max_size          = 2
  min_size          = 1
  health_check_type = "EC2"
  health_check_grace_period = "60"

  name = "nomad-client-arm"

  launch_template {
    id = aws_launch_template.nomad_client_arm_launch_template.id
    version = aws_launch_template.nomad_client_arm_launch_template.latest_version
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