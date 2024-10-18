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
    http = {
        source  = "hashicorp/http"
        version = "~> 3.4.5"
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
      resource_name = "iam/project/${var.hcp_project_id}/service-principal/${var.hcp_sp_name}/workload-identity-provider/${var.hcp_wif_name}"
      token = var.hcp_identity_token
    }
  }
}

provider "vault" "this" {
  config {
    address = component.hcp_clusters.vault_public_endpoint
    token = component.hcp_clusters.hcp_vault_cluster_admin_token
    namespace = "admin"
  }
}

provider "http" "this" {}