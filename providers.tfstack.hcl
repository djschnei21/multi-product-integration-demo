required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.70.0"
    }
    hcp = {
        source  = "hashicorp/hcp"
        version = "~> 0.97.0"
    }
}

provider "aws" "this" {
    config {
        region = var.region
        assume_role_with_web_identity {
          role_arn = var.aws_role_arn
          web_identity_token = var.aws_identity_token
        }
    }
}

provider "hcp" "this" {
  config {
    project_id = var.hcp_project_id
    workload_identity {
      resource_name = var.hcp_resource_name
      token = var.hcp_identity_token
    }
  }
}