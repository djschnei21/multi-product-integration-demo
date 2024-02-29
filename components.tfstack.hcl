variable "aws_account_id" {
  type = string
}

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
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

required_providers {
    doormat = {
        source  = "doormat.hashicorp.services/hashicorp-security/doormat"
        version = "~> 0.0.6"
    }

    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.8.0"
    }

    hcp = {
        source  = "hashicorp/hcp"
        version = "~> 0.66.0"
    }
}

provider "doormat" "this" {}
provider "aws" "this" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}
provider "hcp" "this" {}


component "1_networking" {
  source = "./1_networking"

  inputs = {
    aws_account_id = var.aws_account_id
    stack_id       = var.stack_id
    region         = var.region
    vpc_cidr_block = var.vpc_cidr_block
    vpc_public_subnets = var.vpc_public_subnets
    vpc_private_subnets = var.vpc_private_subnets
    hvn_cidr_block = var.hvn_cidr_block
  }

  providers = {
    doormat = provider.doormat.this
    aws = provider.aws.this
    hcp = provider.hcp.this
  }
}
