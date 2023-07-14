source "amazon-ebs" "example" {
  ami_name      = "hc-security-base-ubuntu-2204-packer-example"
  instance_type = "t2.micro"
  ssh_username  = "ubuntu"
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name                = "hc-security-base-ubuntu-2204*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
      state               = "available"
    }
    owners      = ["888995627335"]
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.example"]

  provisioner "shell" {
    inline = [
      "echo 'hello'",
    ]
  }
}
