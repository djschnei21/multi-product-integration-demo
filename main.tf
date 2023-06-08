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

