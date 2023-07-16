variable "stack_name" {
  type    = string
  default = "hashistack"
}

variable "boundary_admin_username" {
  type = string
}

variable "boundary_admin_password" {
  type = string
}

variable "vault_cluster_tier" {
  type = string
}

variable "consul_cluster_tier" {
  type = string
}
