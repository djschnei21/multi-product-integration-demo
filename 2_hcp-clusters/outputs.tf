output "vault_public_endpoint" {
  value = hcp_vault_cluster.hashistack.vault_public_endpoint_url
}

output "vault_cluster_id" {
  value = hcp_vault_cluster.hashistack.cluster_id
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

output "hcp_vault_cluster_admin_token" {
  value = hcp_vault_cluster_admin_token.token.token
  sensitive = true
}

output "hcp_consul_cluster_admin_token" {
  value = hcp_consul_cluster_admin_token.token.secret_id
  sensitive = true
}