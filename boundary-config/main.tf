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

    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }
}

provider "doormat" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::365006510262:role/tfc-doormat-role_boundary-config"
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

provider "vault" {
  address = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
  token = data.terraform_remote_state.hcp_clusters.outputs.vault_root_token
  namespace = "admin"
}

provider "boundary" {
  addr                            = data.terraform_remote_state.hcp_clusters.outputs.boundary_public_endpoint
  auth_method_login_name = var.boundary_admin_username
  auth_method_password   = var.boundary_admin_password
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

resource "aws_iam_user" "boundary" {
  name = "boundary"
}

resource "aws_iam_access_key" "boundary" {
  user = aws_iam_user.boundary.name
}

data "aws_iam_policy_document" "boundary_ro" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "lb_ro" {
  name   = "test"
  user   = aws_iam_user.boundary.name
  policy = data.aws_iam_policy_document.boundary_ro.json
}

resource "boundary_host_catalog_plugin" "aws" {
  name            = "My aws catalog"
  scope_id        = boundary_scope.project.id
  plugin_name     = "aws"
  attributes_json = jsonencode({ 
    "region" = "${var.region}",
    "disable_credential_rotation" = true
  })

  secrets_json = jsonencode({
    "access_key_id"     = "${aws_iam_access_key.boundary.id}",
    "secret_access_key" = "${aws_iam_access_key.boundary.secret}"
  })
}

resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"

  policy = <<EOT
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}

path "ssh/boundary_role" {
  capabilities = ["read"]
}
EOT
}

resource "vault_token" "boundary_controller" {
  policies = [vault_policy.boundary_controller.name]

  no_parent = true
  renewable = true
  ttl = "24h"

  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account"
  }
}

resource "boundary_credential_store_vault" "vault" {
  name        = "foo"
  description = "My first Vault credential store!"
  address     = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
  token       = vault_token.boundary_controller.client_token 
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_library_vault_ssh_certificate" "vault" {
  name                = "vault"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "ssh/sign/boundary"
  username            = "ubuntu"
}

resource "boundary_host_set_plugin" "nomad_servers" {
  name            = "nomad_servers"
  host_catalog_id = boundary_host_catalog_plugin.aws.id
  attributes_json = jsonencode({ "filters" = ["tag:aws:autoscaling:groupName=nomad-server"] })
}

resource "boundary_host_set_plugin" "nomad_nodes_x86" {
  name            = "nomad_nodes_x86"
  host_catalog_id = boundary_host_catalog_plugin.aws.id
  attributes_json = jsonencode({ "filters" = ["tag:aws:autoscaling:groupName=nomad-client-x86"] })
}

resource "boundary_host_set_plugin" "nomad_nodes_arm" {
  name            = "nomad_nodes_arm"
  host_catalog_id = boundary_host_catalog_plugin.aws.id
  attributes_json = jsonencode({ "filters" = ["tag:aws:autoscaling:groupName=nomad-client-arm"] })
}