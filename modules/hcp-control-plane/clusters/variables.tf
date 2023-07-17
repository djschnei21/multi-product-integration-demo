variable "stack_id" {
  type = string
}

variable "hvn" {
  type = object({
    hvn_id     = string
    self_link  = string
    cidr_block = string
  })
  description = "The HCP HVN to connect to the VPC"
}

variable "boundary_admin_username" {
  type = string
}

variable "boundary_admin_password" {
  type = string
  sensitive = true
}

variable "boundary_cluster_tier" {
  type = string
}

variable "vault_cluster_tier" {
  type = string
}

variable "consul_cluster_tier" {
  type = string
}
