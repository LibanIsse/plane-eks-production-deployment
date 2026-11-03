output "endpoint" {
  description = "RabbitMQ AMQPS connection endpoint"
  value       = aws_mq_broker.main.instances[0].endpoints[0]
}

output "broker_arn" {
  description = "Amazon MQ broker ARN"
  value       = aws_mq_broker.main.arn
}

output "secret_arn" {
  description = "ARN of RabbitMQ credentials in Secrets Manager"
  value       = aws_secretsmanager_secret.rabbitmq.arn
}