output "nomad_sg" {
  value = aws_security_group.nomad.id
}

output "nomad_public_endpoint" {
  value = "http://${aws_alb.nomad.dns_name}"
}

output "ssh_ca_pub_key" {
  value = vault_ssh_secret_backend_ca.ssh_ca.public_key
}

output "nomad_bootstrap_secret_id" {
  value = jsondecode(data.http.bootstrap.response_body).SecretID
  description = "The SecretID from the Nomad ACL bootstrap."
  sensitive = true
}