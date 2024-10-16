component "networking" {
  source = "./1_networking"
  providers = {
    tfe = provider.tfe.this
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