provider "vault" {
  address          = hcp_vault_cluster.hashistack.vault_public_endpoint_url
  token            = hcp_vault_cluster_admin_token.hashistack.token
}

resource "vault_namespace" "hashistack" {
  path = "hashistack"
}

resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("vault/admin-policy.hcl")
}

resource "vault_github_auth_backend" "github" {
  organization = "hashicorp"
}

resource "vault_github_user" "me" {
  backend  = vault_github_auth_backend.github.id
  user     = "djschnei21"
  policies = ["admin"]
}