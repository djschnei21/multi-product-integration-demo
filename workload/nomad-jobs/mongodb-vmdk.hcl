job "demo-fullvm" {
    datacenters = ["dc1"]

    group "fullvm" {
        network {
            mode = "bridge"
            port "mongodb" { } // dynamic port allocation
            port "ssh" { } // dynamic port allocation
        }
        service {
            name = "demo-fullvm-mongodb"
            port = "mongodb"
        }
        service {
            name = "demo-fullvm-ssh"
            port = "ssh"
        }
        task "fullvm" {
            driver = "qemu"
            resources {
                memory  = 2048
                cpu     = 1024
            }
            config {
                image_path = "/opt/nomad/data/ubuntu-ssh.vmdk"
                accelerator = "kvm"
                args = [
                    "-device", 
                    "e1000,netdev=net0", 
                    "-netdev", 
                    "user,id=net0,hostfwd=tcp::${NOMAD_PORT_mongodb}-:27017,hostfwd=tcp::${NOMAD_PORT_ssh}-:22"
                ]
            }
        }
    }
}