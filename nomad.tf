provider "nomad" {
  address = aws_alb.nomad.dns_name
  token = data.vault_kv_secret_v2.bootstrap.data
}

resource "nomad_acl_policy" "developer" {
  name        = "developer"
  description = "Submit jobs to the environment."

  rules_hcl = <<EOT
namespace "default" {
  policy       = "read"
  capabilities = ["submit-job","dispatch-job","read-logs"]
}
EOT
}

resource "nomad_acl_policy" "operations" {
  name        = "operations"
  description = "Administrate the environment."

  rules_hcl = <<EOT
namespace "default" {
  policy = "read"
}

node {
  policy = "write"
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

plugin {
  policy = "list"
}

EOT
}