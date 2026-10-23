variable "vpc_id" {
  description = "VPC where RabbitMQ will run"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for Amazon MQ"
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "Security group associated with EKS nodes"
  type        = string
}