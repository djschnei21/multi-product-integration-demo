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

    boundary = {
      source = "hashicorp/boundary"
      version = "~> 1.1.9"
    }
  }
}

provider "doormat" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::365006510262:role/tfc-doormat-role_nomad-cluster"
}

provider "aws" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "terraform_remote_state" "hcp_clusters" {
  backend = "remote"

  config = {
    organization = var.tfc_account_name
    workspaces = {
      name = "hcp-clusters"
    }
  }
}

provider "boundary" {
  addr                            = data.terraform_remote_state.hcp_clusters.outputs.boundary_public_endpoint
  password_auth_method_login_name = var.boundary_admin_username
  password_auth_method_password   = var.boundary_admin_password
}

resource "boundary_scope" "global" {
  global_scope = true
  scope_id     = "global"
}

resource "boundary_scope" "org" {
  name                     = "demo-org"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name                   = "hashistack-admin"
  description            = "Used to access all VMs that are available and part of the HashiStack"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

# resource "boundary_host_catalog_plugin" "aws" {
#   name            = "My aws catalog"
#   scope_id        = boundary_scope.project.id
#   plugin_name     = "aws"
#   attributes_json = jsonencode({ "region" = "${var.region}" })

#   secrets_json = jsonencode({
#     "access_key_id"     = "aws_access_key_id_value",
#     "secret_access_key" = "aws_secret_access_key_value"
#   })
# }