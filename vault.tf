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
  name  = "nomad_bootstrap"
}

output "bootstrap" {
  value     = data.vault_kv_secret_v2.bootstrap.data["response"]["SecretID"]
  sensitive = true
}