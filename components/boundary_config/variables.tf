variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "vault_public_endpoint" {
  type = string
  description = "The public endpoint of the Vault cluster"
}


