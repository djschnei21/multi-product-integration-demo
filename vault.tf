provider "vault" {
  address = hcp_vault_cluster.hashistack.public_endpoint
  token = hcp_vault_cluster_admin_token.provider.token
  namespace = "admin/"
}

resource "vault_mount" "kvv2" {
  path        = "hashistack-admin"
  type        = "kv"
  options     = { version = "2" }
}

