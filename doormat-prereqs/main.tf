terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "tfc_account_name" {
  type    = string
  default = "djs-tfcb"
}

variable "tfc_workspace_name" {
  type    = string
  default = "multi-cloud-hashistack"
}

resource "aws_iam_role" "doormat_role" {
  name = "tfc-doormat-role"
  tags = {
    hc-service-uri = "app.terraform.io/${var.tfc_account_name}/${var.tfc_workspace_name}"
  }
  max_session_duration = 43200
  assume_role_policy   = data.aws_iam_policy_document.doormat_assume.json
  inline_policy {
    name   = "doormat_permissions"
    policy = data.aws_iam_policy_document.doormat_policy.json
  }
}

data "aws_iam_policy_document" "doormat_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
      "sts:TagSession"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::397512762488:user/doormatServiceUser"] # infrasec_prod   
    }
  }
}

# The following is just for completeness of the sample
data "aws_iam_policy_document" "doormat_policy" {
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
}