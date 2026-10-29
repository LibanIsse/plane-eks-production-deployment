# EKS Pod Identity trust policy
data "aws_iam_policy_document" "cert_manager_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = "plane-eks-cert-manager-role"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_trust.json
}

data "aws_iam_policy_document" "cert_manager_permissions" {

  statement {
    sid    = "ManageDNSChallenge"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = [
      data.aws_route53_zone.eks.arn
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }

  statement {
    sid    = "ReadDNSRecords"
    effect = "Allow"

    actions = [
      "route53:ListResourceRecordSets"
    ]

    resources = [
      data.aws_route53_zone.eks.arn
    ]
  }

  statement {
    sid    = "CheckDNSPropagation"
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = [
      "arn:aws:route53:::change/*"
    ]
  }

  statement {
    sid    = "DiscoverHostedZone"
    effect = "Allow"

    actions = [
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "cert_manager" {
  name        = "plane-eks-cert-manager-policy"
  description = "Allow cert-manager to complete Route 53 DNS-01 challenges"

  policy = data.aws_iam_policy_document.cert_manager_permissions.json
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}

resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name    = var.cluster_name
  namespace       = "cert-manager"
  service_account = "cert-manager"
  role_arn        = aws_iam_role.cert_manager.arn

  depends_on = [
    aws_iam_role_policy_attachment.cert_manager
  ]
}