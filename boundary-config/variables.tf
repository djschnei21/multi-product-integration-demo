variable "aws_account_id" {
  type = string
}

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "tfc_organization" {
  type    = string
}

variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
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

variable "my_email" {
  type = string
  description = "email for the user deploying the stack (required for doormat demo IAM user creation)"
}
