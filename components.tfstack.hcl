component "networking" {
  source = "./components/1_networking"
  providers = {
    aws = provider.aws.this
    hcp = provider.hcp.this
  }
  inputs = {
    region = var.region
    stack_id = var.stack_id
    vpc_cidr_block = var.vpc_cidr_block
    vpc_public_subnets = var.vpc_public_subnets
    vpc_private_subnets = var.vpc_private_subnets
    hvn_cidr_block = var.hvn_cidr_block
  }
}

component "hcp_clusters" {
  source = "./components/2_hcp_clusters"
  providers = {
    hcp = provider.hcp.this
  }
  inputs = {
    stack_id = var.stack_id
    hvn_id = component.networking.hvn_id
    vault_cluster_tier = var.vault_cluster_tier
    consul_cluster_tier = var.consul_cluster_tier
    boundary_cluster_tier = var.boundary_cluster_tier
    boundary_admin_username = var.boundary_admin_username
  }
}

component "nomad_server" {
  source = "./components/3_nomad_server"
  providers = {
    aws = provider.aws.this
    vault = provider.vault.this
    hcp = provider.hcp.this
    http = provider.http.this
  }
  inputs = {
    region = var.region
    stack_id = var.stack_id
    vpc_id = component.networking.vpc_id
    subnet_cidrs = component.networking.subnet_cidrs
    subnet_ids = component.networking.subnet_ids
    hvn_sg_id = component.networking.hvn_sg_id
    consul_ca_file = component.hcp_clusters.consul_ca_file
    consul_config_file = component.hcp_clusters.consul_config_file
    consul_root_token = component.hcp_clusters.hcp_consul_cluster_admin_token
  }
}

removed {
  from = component.hcp-clusters
  source = "./components/2_hcp_clusters"
  providers = {
    hcp = provider.hcp.this
  }
}

removed {
  from = component.nomad-cluster
  source = "./components/3_nomad_server"
  providers = {
    aws = provider.aws.this
    vault = provider.vault.this
    hcp = provider.hcp.this
    http = provider.http.this
  }
}