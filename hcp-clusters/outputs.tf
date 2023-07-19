output "vault_cluster_id" {
  value = hcp_vault_cluster.hashistack.cluster_id
}

output "consul_cluster_id" {
  value = hcp_consul_cluster.hashistack.cluster_id
}

output "boundary_cluster_id" {
  value = hcp_boundary_cluster.hashistack.cluster_id
}

output "vault_private_endpoint" {
  value = hcp_vault_cluster.hashistack.vault_private_endpoint_url
}

output "vault_public_endpoint" {
  value = hcp_vault_cluster.hashistack.vault_private_endpoint_url
}

output "consul_private_endpoint" {
  value = hcp_consul_cluster.hashistack.consul_private_endpoint_url
}

output "consul_public_endpoint" {
  value = hcp_consul_cluster.hashistack.consul_public_endpoint_url
}

output "boundary_endpoint" {
  value = hcp_boundary_cluster.hashistack.cluster_url
}

output "vault_root_token" {
  value = hcp_vault_cluster_admin_token.provider.token
  sensitive = true
}

output "consul_root_token" {
  value = hcp_consul_cluster_root_token.provider.secret_id
  sensitive = true
}