data "hcp_vault_secrets_secret" "nomad_bootstrap_secret_id" {
  app_name    = "hashistack"
  secret_name = "nomad_bootstrap_secret_id"
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

resource "aws_iam_role" "role" {
  name = "nomad-role"

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

resource "aws_iam_role_policy" "policy" {
  name = "nomad-policy"
  role = aws_iam_role.role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "elasticfilesystem:*"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "ec2:*"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "nomad-instance-profile"
  role = aws_iam_role.role.name
}

resource "aws_launch_template" "nomad_client_x86_launch_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_artifact.ubuntu_lunar_hashi_amd.external_identifier
  instance_type = "t3a.medium"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }
  

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ 
      var.nomad_sg,
      var.hvn_sg_id
    ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-node.tpl",
      {
        consul_ca_file     = var.consul_ca_file,
        consul_config_file = var.consul_config_file,
        consul_acl_token   = var.consul_root_token,
        node_pool          = "x86",
        vault_ssh_pub_key  = var.ssh_ca_pub_key,
        vault_public_endpoint = var.vault_public_endpoint
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
  min_size          = 2
  health_check_type = "EC2"
  health_check_grace_period = "60"

  name = "nomad-client-x86"

  launch_template {
    id = aws_launch_template.nomad_client_x86_launch_template.id
    version = aws_launch_template.nomad_client_x86_launch_template.latest_version
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

resource "aws_launch_template" "nomad_client_arm_launch_template" {
  name_prefix   = "lt-"
  image_id      = data.hcp_packer_image.ubuntu_lunar_hashi_arm.cloud_image_id
  instance_type = "t4g.medium"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ 
      var.nomad_sg,
      var.hvn_sg_id
    ]
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  user_data = base64encode(
    templatefile("${path.module}/scripts/nomad-node.tpl",
      {
        consul_ca_file     = var.consul_ca_file,
        consul_config_file = var.consul_config_file,
        consul_acl_token   = var.consul_root_token,
        node_pool          = "arm",
        vault_ssh_pub_key  = var.ssh_ca_pub_key,
        vault_public_endpoint = var.vault_public_endpoint
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
  min_size          = 2
  health_check_type = "EC2"
  health_check_grace_period = "60"

  name = "nomad-client-arm"

  launch_template {
    id = aws_launch_template.nomad_client_arm_launch_template.id
    version = aws_launch_template.nomad_client_arm_launch_template.latest_version
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