output "vault_public_endpoint" {
  value = hcp_vault_cluster.hashistack.vault_public_endpoint_url
}

output "vault_root_token" {
  value = hcp_vault_cluster_admin_token.provider.token
  sensitive = true
}

output "vault_cluster_id" {
  value = hcp_vault_cluster.hashistack.cluster_id
}

output "consul_root_token" {
  value = hcp_consul_cluster_root_token.provider.secret_id
  sensitive = true
}

output "consul_ca_file" {
  value = hcp_consul_cluster.hashistack.consul_ca_file
  sensitive = true
}

output "consul_config_file" {
  value = hcp_consul_cluster.hashistack.consul_config_file
  sensitive = true
}

output "consul_public_endpoint" {
  value = hcp_consul_cluster.hashistack.consul_public_endpoint_url
}

output "boundary_public_endpoint" {
  value = hcp_boundary_cluster.hashistack.cluster_url
}

# Passthrough outputs to enable cascading plans
output "vpc_id" {
  value = data.terraform_remote_state.networking.outputs.vpc_id
}

output "subnet_ids" {
  value = data.terraform_remote_state.networking.outputs.subnet_ids
}

output "subnet_cidrs" {
  value = data.terraform_remote_state.networking.outputs.subnet_cidrs
}

output "hvn_sg_id" {
  value = data.terraform_remote_state.networking.outputs.hvn_sg_id
}