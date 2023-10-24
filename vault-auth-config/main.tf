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

data "tfe_workspace_ids" "all" {
  names = ["*"]
  organization = var.tfc_organization
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

// whoami?
data "vault_generic_secret" "whoami" {
  path = "auth/token/lookup-self"
}

output "whoami" {
  value = nonsensitive(
    merge(data.vault_generic_secret.whoami.data, {
      # Remove the ID from the output, and then the rest is non-sensitive
      "id" = "REDACTED",
      }
    )
  )
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

  roles = [
    {
      workspace_name = terraform.workspace
      token_policies = [
        vault_policy.admin.name
      ]
    },
    {
      workspace_name = "5_nomad-cluster"
      token_policies = [
        vault_policy.admin.name
      ]
    },
    {
      workspace_name = "4_boundary-config"
      token_policies = [
        vault_policy.admin.name
      ]
    },
    {
      workspace_name = "6_nomad-nodes"
      token_policies = [
        vault_policy.admin.name
      ]
    }
  ]
}

resource "vault_jwt_auth_backend_role" "new_role" {
  role_name = "project_role"
  backend   = "tfc/${var.tfc_organization}"

  bound_audiences = ["vault.workload.identity"]
  user_claim      = "terraform_full_workspace"
  role_type       = "jwt"
  token_ttl       = 300
  token_policies  = [vault_policy.admin.name]

  bound_claims = {
    "sub" = "[organization:${var.tfc_organization}:project:hashistack:workspace:*:run_phase:*]"
  }

  bound_claims_type = "glob"
}