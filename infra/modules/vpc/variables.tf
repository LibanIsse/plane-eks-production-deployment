variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private EKS subnets"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "database_subnets" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  default     = ["10.20.21.0/24", "10.20.22.0/24"]
}