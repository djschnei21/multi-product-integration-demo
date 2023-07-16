terraform {}

resource "hcp_vault_cluster" "hashistack" {
  cluster_id      = "${var.stack_name}-vault-cluster"
  hvn_id          = var.hcp_hvn_id
  tier            = var.vault_cluster_tier
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "hashistack" {
  cluster_id = hcp_vault_cluster.hashistack.cluster_id
}

resource "hcp_consul_cluster" "hashistack" {
  cluster_id      = "${var.stack_name}-consul-cluster"
  hvn_id          = var.hcp_hvn_id
  tier            = var.consul_cluster_tier
  public_endpoint = true
  connect_enabled = true
}

resource "hcp_consul_cluster_root_token" "hashistack" {
  cluster_id = hcp_consul_cluster.hashistack.cluster_id
}

resource "hcp_boundary_cluster" "hashistack" {
  cluster_id = "${var.stack_name}-boundary-cluster"
  hvn_id          = var.hcp_hvn_id
  boundary_cluster_tier = var.boundary_cluster_tier
  username   = var.boundary_admin_username
  password   = var.boundary_admin_password
  tier       = var.boundary_cluster_tier
}
