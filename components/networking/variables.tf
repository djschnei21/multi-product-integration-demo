variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR range to create the AWS VPC with"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "A list of public subnet CIDR ranges to create"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "A list of private subnet CIDR ranges to create"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
}