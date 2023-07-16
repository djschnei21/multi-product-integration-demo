check "vault_health_check" {
  data "http" "vault_cluster" {
    url = "${module.hcp_clusters.vault_url}/ui/"
  }

  assert {
    condition = data.http.vault_cluster.status_code == 200
    error_message = "${var.stack_name}-vault-cluster returned an unhealthy status code"
  }
}

check "consul_health_check" {
  data "http" "consul_cluster" {
    url = module.hcp_clusters.consul_url
  }

  assert {
    condition = data.http.consul_cluster.status_code == 200
    error_message = "${var.stack_name}-consul-cluster returned an unhealthy status code"
  }
}

check "boundary_chealth_check" {
  data "http" "boundary_cluster" {
    url = module.hcp_clusters.boundary_url
  }

  assert {
    condition = data.http.boundary_cluster.status_code == 200
    error_message = "${var.stack_name}-boundary-cluster returned an unhealthy status code"
  }
}