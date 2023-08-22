job "demo-mongodb" {
    datacenters = ["dc1"]
    node_pool = "arm"
    type = "service"

    group "mongodb" {
        network {
            mode = "bridge"
            port "http" {
                static = 27017
                to     = 27017
            }
        }

        service {
            name = "demo-mongodb"
            port = "27017"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect{
                sidecar_service {}
            }
        } 

        task "mongodb" {
            driver = "docker"

            config {
                image = "mongo:5"
            }
            env {
                # This will immedietely be rotated be Vault
                MONGO_INITDB_ROOT_USERNAME = "admin"
                MONGO_INITDB_ROOT_PASSWORD = "password"
            }
        }
    }
}