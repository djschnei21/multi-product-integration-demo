component "networking" {
  source = "./1_networking"
  providers = {
    aws = provider.aws.this
    hcp = provider.hcp.this
  }
  inputs = {
    region = var.region
    stack_id = var.stack_id
    vpc_cidr_block = var.vpc_cidr_block
    vpc_public_subnets = var.vpc_public_subnets
    vpc_private_subnets = var.vpc_private_subnets
    hvn_cidr_block = var.hvn_cidr_block
  }
}

component "hcp-clusters" {
  source = "./2_hcp-clusters"
  providers = {
    hcp = provider.hcp.this
  }
  inputs = {
    stack_id = var.stack_id
    hvn_id = component.networking.hvn_id
    vault_cluster_tier = var.vault_cluster_tier
    consul_cluster_tier = var.consul_cluster_tier
    boundary_cluster_tier = var.boundary_cluster_tier
    boundary_admin_username = var.boundary_admin_username
  }
}