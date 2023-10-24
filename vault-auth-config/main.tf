terraform {
  required_providers {
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

data "terraform_remote_state" "hcp_clusters" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "2_hcp-clusters"
    }
  }
}

variable "auth_method" {
  default = "admin_token"
}

resource "tfe_variable" "vault_auth_method" {
  key          = "auth_method"
  value        = "dynamic_creds"
  category     = "terraform"
  workspace_id = data.tfe_workspace_ids.all.ids[terraform.workspace]

  description = "What Vault Auth method should we use?"
}

provider "vault" {
  address = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint

  # If we've not yet bootstrapped... use an admin token for auth
  # otherwise, use dynamic creds (by setting token to null)
  token = var.auth_method == "admin_token" ? data.terraform_remote_state.hcp_clusters.outputs.vault_root_token : null

  namespace = "admin"
}

data "vault_policy_document" "admin" {
  rule {
    path         = "*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "full admin permissions on everything"
  }
}

resource "vault_policy" "admin" {
  name   = "admin"
  policy = data.vault_policy_document.admin.hcl
}

module "tfc-auth" {
  source  = "hashi-strawb/terraform-cloud-jwt-auth/vault"
  version = ">= 0.2.1"

  terraform = {
    org = "djs-tfcb"
  }

  vault = {
    addr      = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
    namespace = "admin"
    auth_path = "tfc/${var.tfc_organization}"
  }

  roles = []
}

data "tfe_project" "project" {
  name = "hashistack"
  organization = "${var.tfc_organization}"
}

resource "vault_jwt_auth_backend" "tfc" {
  path               = "tfc_new/${var.tfc_organization}"
  oidc_discovery_url = "https://app.terraform.io"
  bound_issuer       = "https://app.terraform.io"
}

resource "vault_jwt_auth_backend_role" "project_admin_role" {
  role_name = "project_role"
  backend   = "tfc/${var.tfc_organization}"

  bound_audiences = ["vault.workload.identity"]
  user_claim      = "terraform_full_workspace"
  role_type       = "jwt"
  token_ttl       = 300
  token_policies  = [vault_policy.admin.name]

  bound_claims = {
    "sub" = "[organization:${var.tfc_organization}:project:${tfe_project.project.name}:workspace:*:run_phase:*]"
  }

  bound_claims_type = "glob"
}

resource "tfe_variable_set" "project_vault_auth" {
  name        = "project_vault_auth_${tfe_project.project.name}"
  description = "A set of example variables"
  global      = false
}

resource "tfe_project_variable_set" "project_vault_auth" {
  variable_set_id = tfe_variable_set.project_vault_auth.id
  project_id      = data.tfe_project.project.id
}

// Create variables within the variable set
resource "tfe_variable" "tfc_vault_provider_auth" {
  key          = "TFC_VAULT_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  variable_set_id = tfe_variable_set.project_vault_auth.id
}

resource "tfe_variable" "tfc_vault_addr" {
  key          = "TFC_VAULT_ADDR"
  value        = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
  category     = "env"
  variable_set_id = tfe_variable_set.project_vault_auth.id
}

resource "tfe_variable" "tfc_vault_namespace" {
  key          = "TFC_VAULT_NAMESPACE"
  value        = "admin"
  category     = "env"
  variable_set_id = tfe_variable_set.project_vault_auth.id
}

resource "tfe_variable" "tfc_vault_run_role" {
  key          = "TFC_VAULT_RUN_ROLE"
  value        = vault_jwt_auth_backend_role.project_admin_role.name
  category     = "env"
  variable_set_id = tfe_variable_set.project_vault_auth.id
}

resource "tfe_variable" "tfc_vault_auth_path" {
  key          = "TFC_VAULT_AUTH_PATH"
  value        = vault_jwt_auth_backend.tfc.path
  category     = "env"
  variable_set_id = "tfc/${var.tfc_organization}"
}

resource "tfe_variable" "vault_addr" {
  key          = "VAULT_ADDR"
  value        = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
  category     = "env"
  variable_set_id = tfe_variable_set.project_vault_auth.id
}

resource "tfe_variable" "vault_namespace" {
  key          = "VAULT_NAMESPACE"
  value        = "admin"
  category     = "env"
  variable_set_id = tfe_variable_set.project_vault_auth.id
}

