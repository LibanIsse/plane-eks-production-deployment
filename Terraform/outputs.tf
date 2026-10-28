output "rds_secret_arn" {
  description = "ARN of the RDS-managed PostgreSQL credentials secret"
  value       = module.rds.master_user_secret_arn
}

output "rds_endpoint" {
  description = "PostgreSQL endpoint"
  value       = module.rds.endpoint
}

output "rds_database_name" {
  description = "Plane PostgreSQL database name"
  value       = module.rds.database_name
}

output "valkey_endpoint" {
  description = "ElastiCache Valkey hostname"
  value       = module.elasticache.endpoint
}

output "valkey_port" {
  description = "ElastiCache Valkey port"
  value       = module.elasticache.port
}

output "rabbitmq_endpoint" {
  description = "Amazon MQ secure AMQP endpoint"
  value       = module.amazon_mq.endpoint
}