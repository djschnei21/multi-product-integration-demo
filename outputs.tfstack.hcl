output "vault_public_endpoint"{
  value = component.hcp-clusters.vault_public_endpoint
}

output "consul_public_endpoint"{
  value = component.hcp-clusters.consul_public_endpoint
}

output "boundary_public_endpoint"{
  value = component.hcp-clusters.boundary_public_endpoint
}

output "nomad_public_endpoint"{
  value = component.nomad-cluster.nomad_public_endpoint
}