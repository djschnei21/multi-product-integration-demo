variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "hvn_id" {
  type        = string
  description = "The HVN ID to create the HCP resources in"
}

variable "vault_cluster_tier" {
  type        = string
  description = "The tier used when creating the Vault cluster"
}

variable "consul_cluster_tier" {
  type        = string
  description = "The tier used when creating the Consul cluster"
}

variable "boundary_cluster_tier" {
  type        = string
  description = "The tier used when creating the Boundary cluster"
}

variable "boundary_admin_username" {
  type        = string
  description = "The admin username to be created on the Boundary cluster"
}

variable "boundary_admin_password" {
  type        = string
  description = "The admin password to be created on the Boundary cluster"
  sensitive   = true
}