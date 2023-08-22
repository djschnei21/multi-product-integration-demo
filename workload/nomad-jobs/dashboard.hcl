job "demo-dashboard" {
    datacenters = ["dc1"]
    
    type = "service"
    
    group "dashboard" {
        network {
            mode = "bridge"

            port "http" {
                static = 3100
                to     = 3100
            }
        }
        service {
            name = "demo-dashboard"
            port = "http"

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
        task "wait-for-mongodb" {
            driver = "docker"

            config {
                image = "mongo:5"

                entrypoint = ["/bin/sh"]

                command = "-c"

                args = [
                    "sleep 10 && while ! mongo --host 127.0.0.1 --port 27017 --eval 'db.adminCommand(\"ping\")' --quiet; do sleep 5; done"
                ]
            }
        }
        task "dashboard" {
            driver = "docker"
            lifecycle {
                hook = "poststart"
                sidecar = false
            }
            vault {
                policies = ["demo"]
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