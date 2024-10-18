output "hvn_id" {
  value = hcp_hvn.main.hvn_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.public_subnets
}

output "subnet_cidrs" {
  value = module.vpc.public_subnets_cidr_blocks
}

output "hvn_sg_id" {
  value = module.aws_hcp_network_config.security_group_id
}
