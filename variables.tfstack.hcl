variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "aws_role_arn" {
    type = string
}

variable "aws_identity_token" {
    type      = string
    ephemeral = true
}

variable "hcp_project_id" {
    type = string
}

variable "hcp_identity_token" {
    type      = string
    ephemeral = true
}

variable "hcp_resource_name" {
    type = string 
}

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR range to create the AWS VPC with"
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "A list of public subnet CIDR ranges to create"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "A list of private subnet CIDR ranges to create"
  default     = []
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}