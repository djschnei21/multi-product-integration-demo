variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "stack_id" {
  type        = string
  description = "The name of your stack"
}

variable "vpc_id" {
  type = string
}

variable "subnet_cidrs" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "nomad_sg" {
  type = string
}

variable "hvn_sg_id" {
  type = string
} 

variable "consul_ca_file" {
  type = string
}

variable "consul_config_file" {
  type = string
}

variable "consul_root_token" {
  type = string
}

variable "ssh_ca_pub_key" {
  type = string
}

variable "vault_public_endpoint" {
  type = string
}