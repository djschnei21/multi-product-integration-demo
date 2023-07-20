output "nomad_sg" {
    value = aws_security_group.nomad.id
}

# Passthrough outputs to enable cascading plans
output "consul_root_token" {
  value = data.terraform_remote_state.hcp_clusters.outputs.consul_root_token
  sensitive = true
}

output "consul_ca_file" {
  value = data.terraform_remote_state.hcp_clusters.outputs.consul_ca_file
  sensitive = true
}

output "consul_config_file" {
  value = data.terraform_remote_state.hcp_clusters.outputs.consul_config_file
  sensitive = true
}

output "subnet_ids" {
  value = data.terraform_remote_state.hcp_clusters.outputs.subnet_ids
}

output "hvn_sg_id" {
  value = data.terraform_remote_state.hcp_clusters.outputs.hvn_sg_id
}
