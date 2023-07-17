variable "consul_ent_version" {
  type = string
  default = "1.16.0+ent-1"
}

variable "nomad_ent_version" {
  type = string
  default = "1.6.0~rc.1+ent-1"
}

variable "subnet_id" {
    type = string
}

variable "region" {
    type = string
    default = "us-east-2"
}

source "amazon-ebs" "amd" {
  region     = var.region
  subnet_id  = var.subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners = ["099720109477"] # Canonical
    most_recent = true
  }
  instance_type = "t2.micro"
  ssh_username  = "ubuntu"
  ami_name      = "ubuntu-lunar-hashi-amd64"
  tags = {
    timestamp = "{{timestamp}}"
    nomad_version = var.nomad_ent_version
    consul_version = var.consul_ent_version
  }
}

source "amazon-ebs" "arm" {
  region     = var.region
  subnet_id  = var.subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-arm64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners = ["099720109477"] # Canonical
    most_recent = true
  }
  instance_type = "a1.medium"
  ssh_username  = "ubuntu"
  ami_name      = "ubuntu-lunar-hashi-arm64"
  tags = {
    timestamp = "{{timestamp}}"
    nomad_version = var.nomad_ent_version
    consul_version = var.consul_ent_version
  }
}

build {
  sources = [
    "source.amazon-ebs.amd",
    "source.amazon-ebs.arm"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee -a /etc/apt/sources.list.d/hashicorp.list",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) test\" | sudo tee -a /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get install -y consul-enterprise=${var.consul_ent_version} nomad-enterprise=${var.nomad_ent_version}"
    ]
  }
}