provider "consul" {
  address    = hcp_consul_cluster.hashistack.consul_public_endpoint_url
  datacenter = "${var.stack_id}-consul-cluster"
  token      = hcp_consul_cluster_root_token.provider.secret_id
}

resource "consul_acl_policy" "nomad" {
  name  = "nomad"
  datacenters = ["${var.stack_id}-consul-cluster"]
  rules = <<-RULE
    agent_prefix "" {
      policy = "read"
    }

    acl = "write"

    key_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "write"
    }

    service_prefix "" {
      policy = "write"
    }
    RULE
}

resource "consul_acl_token" "nomad" {
  description = "nomad token"
  policies = ["${consul_acl_policy.nomad.name}"]
  local = true
}

data "consul_acl_token_secret_id" "read" {
    accessor_id = consul_acl_token.nomad.id
}