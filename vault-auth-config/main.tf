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
  role_arn = "arn:aws:iam::365006510262:role/tfc-doormat-role_5_boundary-config"
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
      name = "2_hcp-clusters"
    }
  }
}

variable "auth_method" {
  default = "admin_token"
}

data "tfe_workspace_ids" "all" {
  names = ["*"]
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
    auth_path = "tfc/djc-tfcb"
  }

  roles = [
    {
      workspace_name = terraform.workspace
      token_policies = [
        vault_policy.admin.name
      ]
    },
    {
      workspace_name = "4_nomad-cluster"
      token_policies = [
        vault_policy.admin.name
      ]
    },
    {
      workspace_name = "5_boundary-config"
      token_policies = [
        vault_policy.admin.name
      ]
    },
    {
      workspace_name = "6_nomad-nodes"
      token_policies = [
        vault_policy.admin.name
      ]
    },
  ]
}