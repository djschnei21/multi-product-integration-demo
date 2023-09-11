job "demo-frontend" {
    datacenters = ["dc1"]
    node_pool = "x86"
    type = "service"
    
    group "frontend" {
        network {
            mode = "bridge"

            port "http" {
                static = 3100
                to     = 3100
            }
        }
        service {
            name = "demo-frontend"
            port = "http"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "demo-mongodb"
                            local_bind_port  = 27017
                        }
                    }
                }
            }
        }
        task "frontend" {
            driver = "docker"
            vault {
                policies = ["nomad"]
                change_mode   = "restart"
            }
            template {
                data = <<EOH
MONGOKU_DEFAULT_HOST={{ with secret "mongodb/creds/demo" }}{{ .Data.username }}:{{ .Data.password }}{{ end }}@127.0.0.1:27017
EOH
                destination = "secrets/mongoku.env"
                env         = true
            }

            config {
                image = "huggingface/mongoku:latest"
            }
        }
    }
} 