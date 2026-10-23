data "aws_iam_policy_document" "external_secrets_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "plane-eks-external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_trust.json
}

data "aws_iam_policy_document" "external_secrets_permissions" {
  statement {
    sid    = "ReadPlaneSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = var.secret_arns
  }
}

resource "aws_iam_policy" "external_secrets" {
  name        = "plane-eks-external-secrets-policy"
  description = "Allow ESO to read Plane application secrets"

  policy = data.aws_iam_policy_document.external_secrets_permissions.json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = var.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn

  depends_on = [
    aws_iam_role_policy_attachment.external_secrets
  ]
}