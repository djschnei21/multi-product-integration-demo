variable "aws_account_id" {
  type = string
}

variable "boundary_admin_password" {
  type = string
}

variable "my_email" {
  type = string
}

variable "nomad_license" {
  type = string
}

variable "region" {
  type = string
}

variable "stack_id" {
  type = string
}

variable "auth_method" {
  type = string
  default = "admin_token"
}
