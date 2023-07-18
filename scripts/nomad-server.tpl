#!/bin/bash
set -e

# Add HCP Consul CA and Config
echo '${consul_ca_file}' | sudo base64 -d > /etc/consul.d/ca.pem
echo '${consul_config_file}' | sudo base64 -d > /etc/consul.d/client.temp.0
jq '.bind_addr = "'$(ec2metadata --local-ipv4)'"' /etc/consul.d/client.temp.0 > /etc/consul.d/client.temp.1
jq --arg token "${consul_acl_token}" '.acl += {"tokens":{"agent":"\($token)"}}' /etc/consul.d/client.temp.1 > /etc/consul.d/client.temp.2
jq '.tls.defaults.ca_file = "/etc/consul.d/ca.pem"' /etc/consul.d/client.temp.2 > /etc/consul.d/client.temp.3
jq '.ports = {"grpc":8502}' /etc/consul.d/client.temp.3 > /etc/consul.d/consul.json

sudo systemctl restart consul

# Create Nomad configuration file
cat <<EOF > /etc/nomad.d/nomad.hcl
datacenter = "dc1"
data_dir = "/opt/nomad"
server {
  license_path = "/etc/nomad.d/license.hclic"
  enabled          = true
  bootstrap_expect = 3
}
consul {
  token = "${consul_acl_token}"
  namespace = "${consul_namespace}"
}
bind_addr = "0.0.0.0"
acl {
  enabled    = true
  token_ttl  = "30s"
  policy_ttl = "60s"
  role_ttl   = "60s"
}
EOF
chown root:root /etc/nomad.d/nomad.hcl
chmod 600 /etc/nomad.d/nomad.hcl

echo "${nomad_license}" | sudo tee /etc/nomad.d/license.hclic
chown root:root /etc/nomad.d/license.hclic
chmod 600 /etc/nomad.d/license.hclic
                
sudo systemctl restart nomad
