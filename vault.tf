provider "vault" {
  address = hcp_vault_cluster.hashistack.vault_public_endpoint_url
  token   = hcp_vault_cluster_admin_token.hashistack.token
}

resource "vault_namespace" "hashistack" {
  path = "hashistack"
}

resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("vault/admin-policy.hcl")
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

# Create a user named, "student"
resource "vault_generic_endpoint" "dan" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/dan"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["admins"],
  "password": "${var.vault_password}"
}
EOT
}

resource "vault_consul_secret_backend" "backend" {
  path        = "consul"
  description = "Manages the Consul backend"
  address     = hcp_consul_cluster.hashistack.consul_public_endpoint_url
  token       = hcp_consul_cluster_root_token.hashistack.token
}