required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.70.0"
    }
    hcp = {
        source  = "hashicorp/hcp"
        version = "~> 0.97.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "~> 4.4.0"
    }
    null = {
        source  = "hashicorp/null"
        version = "~> 3.2.3"
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

provider "vault" "this" {
  config {
    address = component.hcp-clusters.vault_public_endpoint
    token = component.hcp-clusters.vault_root_token
    namespace = "admin"
  }
}

provider "null" "this" {}