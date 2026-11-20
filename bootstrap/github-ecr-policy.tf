# Existing Plane ECR repositories.
# These repositories are not created or destroyed by bootstrap Terraform.

locals {
  plane_ecr_repositories = toset([
    "plane/plane-web",
    "plane/plane-space",
    "plane/plane-admin",
    "plane/plane-live",
    "plane/plane-api",
    "plane/plane-proxy",
  ])
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_ecr_push" {
  statement {
    sid       = "AuthenticateToECR"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushPlaneImages"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
    ]

    resources = [
      for repository in local.plane_ecr_repositories :
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/${repository}"
    ]
  }
}

resource "aws_iam_role_policy" "github_ecr_push" {
  name   = "plane-eks-ecr-push"
  role   = aws_iam_role.github_ecr.id
  policy = data.aws_iam_policy_document.github_ecr_push.json
}
