variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "my_email" {
  type = string
  description = "email for the user deploying the stack (required for doormat demo IAM user creation)"
}

variable "vault_public_endpoint" {
  type = string
  description = "The public endpoint of the Vault cluster"
}


