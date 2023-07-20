output "nomad_sg" {
    value = aws_security_group.nomad.id
}

# Passthrough outputs to enable cascading plans
output "consul_root_token" {
  value = data.terraform_remote_state.hcp_clusters.provider.secret_id
  sensitive = true
}

output "consul_ca_file" {
  value = data.terraform_remote_state.hcp_clusters.consul_ca_file
  sensitive = true
}

output "consul_config_file" {
  value = data.terraform_remote_state.hcp_clusters.consul_config_file
  sensitive = true
}

output "subnet_ids" {
  value = data.terraform_remote_state.hcp_clusters.subnet_ids
}

output "hvn_sg_id" {
  value = data.terraform_remote_state.hcp_clusters.hvn_sg_id
}