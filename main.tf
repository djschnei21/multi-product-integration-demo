terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.60.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.16.0"
    }
  }
}