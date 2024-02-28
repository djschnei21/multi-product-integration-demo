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
  enabled          = false
  bootstrap_expect = 3
}
client {
  node_pool = "${node_pool}"
  enabled = true
}
consul {
  token = "${consul_acl_token}"
}
vault {
  enabled = true
  namespace = "admin"
  address = "${vault_public_endpoint}"
}
bind_addr = "0.0.0.0"
acl {
  enabled    = true
  token_ttl  = "30s"
  policy_ttl = "60s"
  role_ttl   = "60s"
}
plugin "docker" {
  config {
    allow_privileged = true
  }
}
EOF
chown root:root /etc/nomad.d/nomad.hcl
chmod 600 /etc/nomad.d/nomad.hcl

echo "${nomad_license}" | sudo tee /etc/nomad.d/license.hclic
chown root:root /etc/nomad.d/license.hclic
chmod 600 /etc/nomad.d/license.hclic
                
sudo systemctl restart nomad

# SSH Vault config

# Your vault public endpoint
ssh_ca_public_key="${vault_ssh_pub_key}"

# Backup existing SSHD config
echo "Backing up existing SSHD config"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Configure SSHD to trust this CA for user cert signed auth
echo "Configuring SSHD to trust the fetched CA"
echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" >> /etc/ssh/sshd_config

# Add the fetched public key to trusted keys
echo "Adding the fetched public key to trusted keys"
echo $ssh_ca_public_key >> /etc/ssh/trusted-user-ca-keys.pem

# Restart SSHD service
echo "Restarting SSHD service"
sudo service sshd restart

echo "Script executed successfully"