# Allow EKS Pod Identity to assume the role
data "aws_iam_policy_document" "load_balancer_controller_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# IAM role used by the AWS Load Balancer Controller
resource "aws_iam_role" "load_balancer_controller" {
  name               = "plane-eks-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.load_balancer_controller_trust.json
}

# Permissions from the official controller IAM policy
resource "aws_iam_policy" "load_balancer_controller" {
  name        = "plane-eks-load-balancer-controller-policy"
  description = "AWS Load Balancer Controller permissions"

  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}

# Attach the permissions to the role
resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}

# Associate the controller ServiceAccount with the IAM role
resource "aws_eks_pod_identity_association" "load_balancer_controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.load_balancer_controller.arn

  depends_on = [
    aws_iam_role_policy_attachment.load_balancer_controller
  ]
}