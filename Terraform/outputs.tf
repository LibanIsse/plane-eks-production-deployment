output "rds_secret_arn" {
  description = "ARN of the RDS-managed PostgreSQL credentials secret"
  value       = module.rds.master_user_secret_arn
}