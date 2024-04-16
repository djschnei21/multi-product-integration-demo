variable "boundary_admin_password" {
  type = string
}

variable "my_email" {
  type = string
}

variable "nomad_license" {
  type = string
}

variable "tfc_organization" {
  type = string
}

variable "auth_method" {
  type = string
  default = "admin_token"
}

