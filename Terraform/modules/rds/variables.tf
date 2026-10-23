variable "vpc_id" {
  description = "VPC where RDS will be deployed"
  type        = string
}

variable "database_subnet_ids" {
  description = "Private database subnet IDs"
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "Security group associated with EKS worker nodes"
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name"
  type        = string
  default     = "plane"
}