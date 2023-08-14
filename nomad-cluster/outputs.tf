output "nomad_sg" {
    value = aws_security_group.nomad.id
}

output "nomad_public_endpoint" {
  value = "http://${aws_alb.nomad.dns_name}"
}

output "bootstrap_kv" {
  value = vault_mount.kvv2.path
}

output "ssh_ca_pub_key" {
  value = vault_ssh_secret_backend_ca.ssh_ca.public_key
}

# Passthrough outputs to enable cascading plans
output "vault_public_endpoint" {
  value = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
}

output "vault_root_token" {
  value = data.terraform_remote_state.hcp_clusters.outputs.vault_root_token
  sensitive = true
}

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
