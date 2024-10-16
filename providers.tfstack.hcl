required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.70.0"
    }
    hcp = {
        source  = "hashicorp/hcp"
        version = "~> 0.97.0"
    }
}

provider "aws" "this" {
    config {
        region = var.region
    }
}

provider "hcp" "this" {}