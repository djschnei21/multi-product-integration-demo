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

resource "hcp_consul_cluster" "hashistack" {
  cluster_id      = "consul-cluster"
  hvn_id          = hcp_hvn.hashistack.hvn_id
  tier            = "development"
  public_endpoint = true
  connect_enabled = true
}

resource "hcp_boundary_cluster" "hashistack" {
  cluster_id = "boundary-cluster"
  username   = "admin"
  password   = var.boundary_password
}

resource "hcp_packer_channel" "staging" {
  name        = "staging"
  bucket_name = "ubuntu"
}

resource "hcp_packer_channel" "production" {
  name        = "production"
  bucket_name = "ubuntu"
}