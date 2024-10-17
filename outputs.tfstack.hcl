output "vault_public_endpoint" {
  type = string
  value = component.hcp-clusters.vault_public_endpoint
}

output "consul_public_endpoint" {
  type = string
  value = component.hcp-clusters.consul_public_endpoint
}

output "boundary_public_endpoint" {
  type = string
  value = component.hcp-clusters.boundary_public_endpoint
}

output "nomad_public_endpoint" {
  type = string
  value = component.nomad-cluster.nomad_public_endpoint
}

output "nomad_bootstrap_secret_id" {
  type = string
  value = component.nomad-cluster.nomad_bootstrap_secret_id
}