variable "subnet_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-2"
}

source "amazon-ebs" "amd" {
  region                      = var.region
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "RHEL-9.2.0_HVM-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["309956199498"] # Canonical
    most_recent = true
  }
  instance_type = "t3a.medium"
  ssh_username  = "ec2-user"
  ami_name      = "rhel9-amd64-{{timestamp}}"
  tags = {
    timestamp      = "{{timestamp}}"
    consul_enabled = true
    nomad_enabled = true
  }
}

build {
  sources = [
    "source.amazon-ebs.amd",
  ]

  hcp_packer_registry {
    bucket_name = "rhel9-hashi"
    description = "RHEL9 with Nomad and Consul installed"

    bucket_labels = {
      "os"             = "RHEL",
      "rhel-version"   = "9.2",
    }

    build_labels = {
      "timestamp"      = timestamp()
      "consul_enabled" = true
      "nomad_enabled" = true
    }
  }

  provisioner "shell" {
    inline = [
      "sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "sudo dnf update -y && sudo dnf upgrade -y",
      "sudo dnf install -y consul nomad-enterprise docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "curl -L -o cni-plugins.tgz \"https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)\"-v1.3.0.tgz",
      "sudo mkdir -p /opt/cni/bin",
      "sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz"
    ]
  }
}