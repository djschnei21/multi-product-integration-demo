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