resource "aws_security_group" "rabbitmq" {
  name        = "plane-rabbitmq-sg"
  description = "Security group for Plane RabbitMQ"
  vpc_id      = var.vpc_id

  tags = {
    Name = "plane-rabbitmq-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq" {
  security_group_id            = aws_security_group.rabbitmq.id
  referenced_security_group_id = var.eks_node_security_group_id

  from_port   = 5671
  to_port     = 5671
  ip_protocol = "tcp"

  description = "Allow secure RabbitMQ connections from EKS"
}

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "rabbitmq" {
  name                    = "plane/rabbitmq/credentials"
  description             = "RabbitMQ credentials for Plane"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id

  secret_string = jsonencode({
    username = "planeadmin"
    password = random_password.rabbitmq.result
  })
}

resource "aws_mq_broker" "main" {
  broker_name = "plane-rabbitmq"

  engine_type        = "RabbitMQ"
  engine_version     = "4.2"
  host_instance_type = "mq.m7g.medium"

  deployment_mode     = "SINGLE_INSTANCE"
  publicly_accessible = false

  subnet_ids = [var.subnet_ids[0]]

  security_groups = [
    aws_security_group.rabbitmq.id
  ]

  auto_minor_version_upgrade = true

  logs {
    general = true
  }

  user {
    username = "planeadmin"
    password = random_password.rabbitmq.result
  }

  tags = {
    Name = "plane-rabbitmq"
  }
}