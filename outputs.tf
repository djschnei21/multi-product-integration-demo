output "vault_url" {
  value = hcp_vault_cluster.hashistack.vault_public_endpoint_url
}

output "consul_url" {
  value = hcp_consul_cluster.hashistack.consul_public_endpoint_url
}

output "boundary_url" {
  value = hcp_boundary_cluster.hashistack.cluster_url
}