data "aws_route53_zone" "eks" {
  name         = var.route53_zone_name
  private_zone = false
}

# Allow EKS Pod Identity to assume the IAM role
data "aws_iam_policy_document" "external_dns_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "plane-eks-external-dns-role"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust.json
}

data "aws_iam_policy_document" "external_dns_permissions" {

  statement {
    sid    = "ManagePlaneDNSRecords"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = [
      data.aws_route53_zone.eks.arn
    ]
  }

  statement {
    sid    = "DiscoverHostedZones"
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "plane-eks-external-dns-policy"
  description = "Allow ExternalDNS to manage Plane Route 53 records"

  policy = data.aws_iam_policy_document.external_dns_permissions.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = var.cluster_name
  namespace       = "external-dns"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn

  depends_on = [
    aws_iam_role_policy_attachment.external_dns
  ]
}