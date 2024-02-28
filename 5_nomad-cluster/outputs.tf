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