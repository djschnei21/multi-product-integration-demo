# variable "tfc_organization" {
#   type = string
# }

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "tfc_organization" {
  type    = string
}

variable "boundary_admin_username" {
  type        = string
  description = "The admin username to be created on the Boundary cluster"
  default     = "admin"
}

variable "boundary_admin_password" {
  type        = string
  description = "The admin user's password on the Boundary cluster"
  sensitive   = true
}

variable "boundary_cluster_tier" {
  type        = string
  description = "The tier used when creating the Boundary cluster"
  default     = "plus"
}

variable "vault_cluster_tier" {
  type        = string
  description = "The tier used when creating the Vault cluster"
  default     = "plus_small"
}

variable "consul_cluster_tier" {
  type        = string
  description = "The tier used when creating the Consul cluster"
  default     = "development"
}