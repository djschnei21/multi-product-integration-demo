provider "vault" {
  address          = hcp_vault_cluster.hashistack.vault_public_endpoint_url
  token            = hcp_vault_cluster_admin_token.hashistack.token
}

resource "vault_namespace" "hashistack" {
  path = "hashistack"
}