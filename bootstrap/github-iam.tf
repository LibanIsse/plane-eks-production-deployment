locals {
  github_repository = "LibanIsse/plane-eks-production-deployment"

  github_main_subject = "repo:${local.github_repository}:ref:refs/heads/main"
}

data "aws_iam_policy_document" "github_main_trust" {
  statement {
    sid     = "AllowGitHubMain"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_main_subject]
    }
  }
}

resource "aws_iam_role" "github_terraform" {
  name               = "plane-eks-github-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_main_trust.json

  tags = {
    ManagedBy = "Terraform"
    Project   = "plane-eks"
    Purpose   = "github-terraform"
  }
}

resource "aws_iam_role" "github_ecr" {
  name               = "plane-eks-github-ecr"
  assume_role_policy = data.aws_iam_policy_document.github_main_trust.json

  tags = {
    ManagedBy = "Terraform"
    Project   = "plane-eks"
    Purpose   = "github-ecr"
  }
}

output "github_terraform_role_arn" {
  description = "IAM role used by GitHub Actions Terraform workflows"
  value       = aws_iam_role.github_terraform.arn
}

output "github_ecr_role_arn" {
  description = "IAM role used by GitHub Actions ECR publishing workflows"
  value       = aws_iam_role.github_ecr.arn
}
