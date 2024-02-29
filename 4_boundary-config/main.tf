terraform {
  required_providers {
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

    boundary = {
      source = "hashicorp/boundary"
      version = "~> 1.1.9"
    }

    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }
}

provider "doormat" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/tfc-doormat-role_4_boundary-config"
}

provider "aws" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "terraform_remote_state" "hcp_clusters" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "2_hcp-clusters"
    }
  }
}

provider "vault" {}

provider "boundary" {
  addr  = data.terraform_remote_state.hcp_clusters.outputs.boundary_public_endpoint
  auth_method_login_name = var.boundary_admin_username
  auth_method_password   = var.boundary_admin_password
}

resource "boundary_scope" "global" {
  global_scope = true
  scope_id     = "global"
}

resource "boundary_scope" "org" {
  name                     = "demo-org"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name                   = "hashistack-admin"
  description            = "Used to access all VMs that are available and part of the HashiStack"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

# Grab some information about and from the current AWS account.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy" "demo_user_permissions_boundary" {
  name = "DemoUser"
}

# Create the user to be used in Boundary for dynamic host discovery. Then attach the policy to the user.
resource "aws_iam_user" "boundary_dynamic_host_catalog" {
  name                 = "demo-${var.my_email}-bdhc"
  permissions_boundary = data.aws_iam_policy.demo_user_permissions_boundary.arn
  force_destroy        = true
}

resource "aws_iam_user_policy_attachment" "boundary_dynamic_host_catalog" {
  user       = aws_iam_user.boundary_dynamic_host_catalog.name
  policy_arn = data.aws_iam_policy.demo_user_permissions_boundary.arn
}

# Generate some secrets to pass in to the Boundary configuration.
# WARNING: These secrets are not encrypted in the state file. Ensure that you do not commit your state file!
resource "aws_iam_access_key" "boundary_dynamic_host_catalog" {
  user = aws_iam_user.boundary_dynamic_host_catalog.name

  depends_on = [aws_iam_user_policy_attachment.boundary_dynamic_host_catalog]
}

# AWS is eventually-consistent when creating IAM Users. Introduce a wait
# before handing credentails off to boundary.
resource "time_sleep" "boundary_dynamic_host_catalog_user_ready" {
  create_duration = "30s"
  depends_on = [aws_iam_access_key.boundary_dynamic_host_catalog]
}

resource "boundary_host_catalog_plugin" "aws" {
  depends_on = [ time_sleep.boundary_dynamic_host_catalog_user_ready ]
  name            = "My aws catalog"
  scope_id        = boundary_scope.project.id
  plugin_name     = "aws"
  attributes_json = jsonencode({ 
    "region" = "${var.region}",
    "disable_credential_rotation" = true,
  })

  secrets_json = jsonencode({
    "access_key_id"     = "${aws_iam_access_key.boundary_dynamic_host_catalog.id}",
    "secret_access_key" = "${aws_iam_access_key.boundary_dynamic_host_catalog.secret}"
  })
}

resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"

  policy = <<EOT
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}

path "ssh/issue/boundary_role" {
  capabilities = ["create", "update"]
}

path "ssh/sign/boundary_role" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_token" "boundary_controller" {
  policies = [ vault_policy.boundary_controller.name ]

  no_parent = true
  renewable = true

  period = "20m"

  metadata = {
    "purpose" = "service-account"
  }
}

resource "boundary_credential_store_vault" "vault" {
  name        = "foo"
  description = "My first Vault credential store!"
  address     = data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint
  token       = vault_token.boundary_controller.client_token 
  scope_id    = boundary_scope.project.id
  namespace   = "admin"
}

resource "boundary_credential_library_vault_ssh_certificate" "vault" {
  name                = "vault"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "ssh/sign/boundary_role"
  username            = "ubuntu"
  key_type            = "ed25519"
}

resource "boundary_host_set_plugin" "nomad_servers" {
  name            = "nomad_servers"
  host_catalog_id = boundary_host_catalog_plugin.aws.id
  attributes_json = jsonencode({ "filters" = ["tag:aws:autoscaling:groupName=nomad-server"] })
  preferred_endpoints   = ["dns:*.com"]
}

resource "boundary_host_set_plugin" "nomad_nodes_x86" {
  name            = "nomad_nodes_x86"
  host_catalog_id = boundary_host_catalog_plugin.aws.id
  attributes_json = jsonencode({ "filters" = ["tag:aws:autoscaling:groupName=nomad-client-x86"] })
  preferred_endpoints   = ["dns:*.com"]
}

resource "boundary_host_set_plugin" "nomad_nodes_arm" {
  name            = "nomad_nodes_arm"
  host_catalog_id = boundary_host_catalog_plugin.aws.id
  attributes_json = jsonencode({ "filters" = ["tag:aws:autoscaling:groupName=nomad-client-arm"] })
  preferred_endpoints   = ["dns:*.com"]
}

resource "boundary_target" "nomad_servers" {
  name         = "Nomad Servers"
  type         = "ssh"
  default_port = "22"
  scope_id     = boundary_scope.project.id
  host_source_ids = [
    boundary_host_set_plugin.nomad_servers.id 
  ]
  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.vault.id 
  ]
}

resource "boundary_target" "nomad_nodes_x86" {
  name         = "Nomad x86 Nodes"
  type         = "ssh"
  default_port = "22"
  scope_id     = boundary_scope.project.id
  host_source_ids = [
    boundary_host_set_plugin.nomad_nodes_x86.id 
  ]
  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.vault.id 
  ]
}

resource "boundary_target" "nomad_nodes_arm" {
  name         = "Nomad Arm Nodes"
  type         = "ssh"
  default_port = "22"
  scope_id     = boundary_scope.project.id
  host_source_ids = [
    boundary_host_set_plugin.nomad_nodes_arm.id 
  ]
  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.vault.id 
  ]
}
