terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.60.0"
    }
  }
}

resource "hcp_hvn" "hashistack" {
  hvn_id         = "hashistack-hvn"
  cloud_provider = "aws"
  region         = "us-east-1"
  cidr_block     = "172.25.16.0/20"
}

resource "hcp_vault_cluster" "hashistack" {
  cluster_id = "vault-cluster"
  hvn_id     = hcp_hvn.hashistack.hvn_id
  tier       = "starter_small"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcp_consul_cluster" "hashistack" {
  cluster_id = "consul-cluster"
  hvn_id     = hcp_hvn.hashistack.id
  tier       = "development"
}