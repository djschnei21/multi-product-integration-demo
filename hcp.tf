provider "hcp" {}

resource "hcp_hvn" "hashistack" {
  hvn_id         = "hashistack-hvn"
  cloud_provider = "aws"
  region         = "us-east-1"
  cidr_block     = "172.25.16.0/20"
}

resource "hcp_vault_cluster" "hashistack" {
  cluster_id      = "vault-cluster"
  hvn_id          = hcp_hvn.hashistack.hvn_id
  tier            = "starter_small"
  public_endpoint = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcp_vault_cluster_admin_token" "hashistack" {
  cluster_id = hcp_vault_cluster.hashistack.cluster_id
}

resource "hcp_consul_cluster" "hashistack" {
  cluster_id      = "consul-cluster"
  hvn_id          = hcp_hvn.hashistack.hvn_id
  tier            = "development"
  public_endpoint = true
  connect_enabled = true
}

resource "hcp_consul_cluster_root_token" "example" {
  cluster_id = hcp_consul_cluster.hashistack.cluster_id
}

resource "hcp_boundary_cluster" "hashistack" {
  cluster_id = "boundary-cluster"
  username   = "admin"
  password   = var.boundary_password
}
