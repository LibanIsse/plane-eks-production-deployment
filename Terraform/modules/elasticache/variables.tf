variable "vpc_id" {
  description = "VPC containing the ElastiCache resources"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for ElastiCache"
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "Security group used by EKS worker nodes"
  type        = string
}
