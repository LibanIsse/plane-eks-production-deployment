variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "plane-eks"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36"
}

variable "private_subnet_ids" {
  description = "Private subnets from the VPC module"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "IPv4 CIDR ranges allowed to access the EKS API"
  type        = list(string)
}