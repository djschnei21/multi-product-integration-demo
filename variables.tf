variable "stack_id" {
  type        = string
  description = "The name of your stack"
  default     = "hashistack"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-east-2"
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

variable "hvn_region" {
  type        = string
  description = "The AWS region to create HCP resources in"
  default     = "us-east-2"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "boundary_admin_username" {
  type = string
  description = "The admin username to be created on the Boundary cluster"
  default     = "admin"
}

variable "boundary_admin_password" {
  type      = string
  description = "The admin user's password on the Boundary cluster"
  sensitive = true
}

variable "boundary_cluster_tier" {
  type = string
  description = "The tier used when creating the Boundary cluster"
  default = "plus"
}

variable "vault_cluster_tier" {
  type = string
  description = "The tier used when creating the Vault cluster"
  default = "plus_small"
}

variable "consul_cluster_tier" {
  type = string
  description = "The tier used when creating the Consul cluster"
  default = "development"
}

variable "ssm" {
  type        = bool
  description = "Whether to enable SSM on the EC2 host"
  default     = true
}

variable "install_demo_app" {
  type        = bool
  description = "Whether to install demo app"
  default     = false
}