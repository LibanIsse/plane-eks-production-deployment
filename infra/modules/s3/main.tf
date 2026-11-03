resource "aws_s3_bucket" "plane" {
  bucket_prefix = "plane-eks-files-"

  tags = {
    Name    = "plane-eks-files"
    Project = "EKS-IaC-1"
  }
}

resource "aws_s3_bucket_public_access_block" "plane" {
  bucket = aws_s3_bucket.plane.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "plane" {
  bucket = aws_s3_bucket.plane.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "plane" {
  bucket = aws_s3_bucket.plane.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "plane" {
  bucket = aws_s3_bucket.plane.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.plane]
}

data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "plane_s3" {
  name               = "plane-eks-s3-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json
}

data "aws_iam_policy_document" "plane_s3" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.plane.arn
    ]
  }

  statement {
    sid    = "ManageObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.plane.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "plane_s3" {
  name        = "plane-eks-s3-policy"
  description = "Allow Plane to access its application S3 bucket"

  policy = data.aws_iam_policy_document.plane_s3.json
}

resource "aws_iam_role_policy_attachment" "plane_s3" {
  role       = aws_iam_role.plane_s3.name
  policy_arn = aws_iam_policy.plane_s3.arn
}

resource "aws_eks_pod_identity_association" "plane_s3" {
  cluster_name    = var.cluster_name
  namespace       = "plane"
  service_account = "plane-s3"
  role_arn        = aws_iam_role.plane_s3.arn

  depends_on = [
    aws_iam_role_policy_attachment.plane_s3
  ]
}