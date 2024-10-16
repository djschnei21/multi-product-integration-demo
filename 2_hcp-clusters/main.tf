terraform {}

data "hcp_vault_secrets_app" "boundary_admin_password" {
  app_name = "hashistack"
}

resource "hcp_vault_cluster" "hashistack" {
  cluster_id      = "${var.stack_id}-vault-cluster"
  hvn_id          = var.hvn_id
  tier            = var.vault_cluster_tier
  public_endpoint = true
}

resource "hcp_consul_cluster" "hashistack" {
  cluster_id      = "${var.stack_id}-consul-cluster"
  hvn_id          = var.hvn_id
  tier            = var.consul_cluster_tier
  public_endpoint = true
  connect_enabled = true
}

resource "hcp_boundary_cluster" "hashistack" {
  cluster_id = "${var.stack_id}-boundary-cluster"
  tier       = var.boundary_cluster_tier
  username   = var.boundary_admin_username
  password   = data.hcp_vault_secrets_app.boundary_admin_password.secret_value
}