# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# Public subnet IDs
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

# Private EKS subnet IDs
output "private_subnet_ids" {
  description = "IDs of private EKS subnets"
  value       = aws_subnet.private[*].id
}

# Database subnet IDs
output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = aws_subnet.database[*].id
}