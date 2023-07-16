output "vault_url" {
  value = hcp_vault_cluster.hashistack.vault_public_endpoint_url
}

output "vault_admin_token" {
  sensitive = true
  value = hcp_vault_cluster_admin_token.hashistack.token
}

output "consul_url" {
  value = hcp_consul_cluster.hashistack.consul_public_endpoint_url
}

output "consul_admin_token" {
  sensitive = true
  value = hcp_consul_cluster_root_token.hashistack.token
}

output "boundary_url" {
  value = hcp_boundary_cluster.hashistack.cluster_url
}