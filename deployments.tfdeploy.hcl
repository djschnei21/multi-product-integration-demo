identity_token "aws" {
  audience = ["aws.workload.identity"]
}

identity_token "hcp" {
  audience = ["hcp.workload.identity"]
}

deployment "dev" {
    inputs = {
        aws_account_id = "365006510262"
        aws_role_name  = "tfc-wif"
        region         = "us-east-2"
        stack_id       = "dev"
        hcp_resource_name = "iam/project/092c0213-a9d0-4489-bfe1-e672a3e38392/service-principal/hcp-terraform/workload-identity-provider/hcp-terraform-dynamic-credentials"
        aws_token      = identity_token.aws
        hcp_token      = identity_token.hcp
    }
}