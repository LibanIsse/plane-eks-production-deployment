output "endpoint" {
  description = "Valkey serverless cache hostname"
  value       = aws_elasticache_serverless_cache.main.endpoint[0].address
}

output "port" {
  description = "Valkey serverless cache port"
  value       = aws_elasticache_serverless_cache.main.endpoint[0].port
}

output "arn" {
  description = "Valkey serverless cache ARN"
  value       = aws_elasticache_serverless_cache.main.arn
}