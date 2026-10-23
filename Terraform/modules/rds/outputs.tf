output "endpoint" {
  description = "PostgreSQL connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.main.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed secret in Secrets Manager"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}