provider "vault" {
  address          = hcp_vault_cluster.hashistack.public_endpoint
  token            = hcp_vault_cluster_admin_token.hashistack.token
  skip_child_token = true
}

resource "vault_namespace" "hashistack" {
  path = "hashistack"
}