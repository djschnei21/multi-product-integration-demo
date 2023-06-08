terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.60.0"
    }
  }
}

variable "boundary_password" {
  type = string
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

resource "hcp_boundary_cluster" "hashistack" {
  cluster_id = "boundary-cluster"
  username   = "admin"
  password   = var.boundary_password
}

output "vault_url" {
  value = hcp_vault_cluster.hashistack.public_endpoint
}

output "consul_url" {
  value = hcp_consul_cluster.hashistack.consul_public_endpoint_url
}

output "boundary_url" {
  value = hcp_boundary_cluster.hashistack.cluster_url
}