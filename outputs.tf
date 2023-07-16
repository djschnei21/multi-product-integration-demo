output "aws_vpc_arn" {
  value = module.aws_landing_zone.vpc_arn
}

output "aws_vpc_id" {
  value = module.aws_landing_zone.vpc_id
}

output "hcp_hvn_id" {
    value = module.hcp_hvn_aws.hcp_hvn_id
}

output "vault_url" {
  value = module.hcp_clusters.vault_url
}

output "vault_admin_token" {
  sensitive = true
  value = module.hcp_clusters.vault_admin_token
}

output "consul_url" {
  value = module.hcp_clusters.consul_url
}

output "consul_admin_token" {
  sensitive = true
  value = module.hcp_clusters.consul_admin_token
}

output "boundary_url" {
  value = module.hcp_clusters.boundary_url
}