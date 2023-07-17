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

module "aws_landing_zone" {
  source     = "./modules/csp-landing-zones/aws"
  stack_name = var.stack_name
}

# module "hcp_hvn_aws" {
#   depends_on = [module.aws_landing_zone] #required because dependency on default SG being created isnt implicit
#   source     = "./modules/hcp-control-plane/hashicorp-virtual-network"
#   stack_name = var.stack_name
#   aws_vpc_id = module.aws_landing_zone.vpc_id
# }

# module "hcp_clusters" {
#   source                  = "./modules/hcp-control-plane/clusters"
#   stack_name              = var.stack_name
#   hcp_hvn_id              = module.hcp_hvn_aws.hcp_hvn_id
#   boundary_cluster_tier   = var.boundary_cluster_tier
#   boundary_admin_username = var.boundary_admin_username
#   boundary_admin_password = var.boundary_admin_password
#   vault_cluster_tier      = var.vault_cluster_tier
#   consul_cluster_tier     = var.consul_cluster_tier
# }