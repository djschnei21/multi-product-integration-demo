# Manage auth methods broadly across Vault
path "*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}