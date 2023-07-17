terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.6"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.66.0"
    }
  }
}

provider "doormat" {}

provider "hcp" {}

provider "aws" {
  region     = "us-east-1"
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::365006510262:role/tfc-doormat-role"
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "3.10.0"

#   azs                  = data.aws_availability_zones.available.names
#   cidr                 = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   name                 = "${var.cluster_id}-vpc"
#   private_subnets      = []
#   public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
# }

# resource "hcp_hvn" "main" {
#   hvn_id         = var.hvn_id
#   cloud_provider = "aws"
#   region         = var.hvn_region
#   cidr_block     = var.hvn_cidr_block
# }

# module "aws_hcp_consul" {
#   source  = "hashicorp/hcp-consul/aws"
#   version = "~> 0.12.1"

#   hvn             = hcp_hvn.main
#   vpc_id          = module.vpc.vpc_id
#   subnet_ids      = module.vpc.public_subnets
#   route_table_ids = module.vpc.public_route_table_ids
# }