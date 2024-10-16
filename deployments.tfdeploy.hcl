identity_token "aws" {
  audience = ["aws.workload.identity"]
}

identity_token "hcp" {
  audience = ["hcp.workload.identity"]
}

deployment "dev" {
    inputs = {
        region         = "us-east-2"
        stack_id       = "dev"
        aws_role_arn   = "arn:aws:iam::365006510262:role/tfc-wif"
        hcp_project_id = "092c0213-a9d0-4489-bfe1-e672a3e38392"
        hcp_resource_name = "hcp-terraform-dynamic-credentials"
        aws_identity_token      = identity_token.aws.jwt
        hcp_identity_token      = identity_token.hcp.jwt
    }
}