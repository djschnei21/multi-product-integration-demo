provider "vault" {
  address = hcp_vault_cluster.hashistack.vault_public_endpoint_url
  token = hcp_vault_cluster_admin_token.provider.token
  namespace = "admin"
}

resource "vault_mount" "kvv2" {
  path        = "hashistack-admin"
  type        = "kv"
  options     = { version = "2" }
}

data "vault_kv_secret_v2" "bootstrap" {
  depends_on = [ null_resource.bootstrap_acl ]
  mount = vault_mount.kvv2.path
  name  = "nomad_bootstrap/SecretID"
}

resource "vault_nomad_secret_backend" "config" {
    backend                   = "nomad"
    default_lease_ttl_seconds = "3600"
    max_lease_ttl_seconds     = "7200"
    max_ttl                   = "240"
    address                   = aws_alb.nomad.dns_name
    token                     = data.vault_kv_secret_v2.bootstrap.data
    ttl                       = "120"
}

resource "vault_nomad_secret_role" "developer" {
  backend   = vault_nomad_secret_backend.config.backend
  role      = "developer"
  type      = "client"
  policies  = [ nomad_acl_policy.developer.name ]
}

resource "vault_nomad_secret_role" "operations" {
  backend   = vault_nomad_secret_backend.config.backend
  role      = "developer"
  type      = "client"
  policies  = [ nomad_acl_policy.operations.name ]
}