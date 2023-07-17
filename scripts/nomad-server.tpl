#!/bin/bash
set -e

# Add HCP Consul CA and Config
echo '${consul_ca_file}' | sudo base64 -d > /etc/consul.d/consul_ca.pem
echo '${consul_config_file}' | sudo base64 -d > /etc/consul.d/consul.hcl

sudo systemctl restart consul

# Create Nomad configuration file
cat <<EOF > /etc/nomad.d/config.hcl
datacenter = "dc1"
data_dir = "/opt/nomad"
license_path = "/etc/nomad.d/license.hclic"
server {
  enabled          = true
  bootstrap_expect = 3
}
EOF
chown root:root /etc/nomad.d/config.hcl
chmod 600 /etc/nomad.d/config.hcl

echo '${nomad_license}' | sudo tee /etc/nomad.d/nomad.license
chown root:root /etc/nomad.d/nomad.license
chmod 600 /etc/nomad.d/nomad.license
                
sudo systemctl restart nomad
