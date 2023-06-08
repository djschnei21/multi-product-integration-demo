provider "vault" {
  token = hcp_vault_cluster_admin_token.hashistack.token
}

resource "vault_namespace" "hashistack" {
  path = "hashistack"
}