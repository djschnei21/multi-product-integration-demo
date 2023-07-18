provider "vault" {
  address = hcp_vault_cluster.hashistack.vault_public_endpoint_url
  token = hcp_vault_cluster_admin_token.provider.token
  namespace = "admin"
}

resource "vault_mount" "kvv2" {
  path        = "hashistack-admin"
  type        = "kv"
  options     = { version = "2" }
}

