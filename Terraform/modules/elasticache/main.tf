resource "aws_elasticache_serverless_cache" "main" {
  name                 = "plane-valkey"
  engine               = "valkey"
  major_engine_version = "8"

  description = "Serverless Valkey cache for Plane"

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.valkey.id]

  cache_usage_limits {
    data_storage {
      maximum = 1
      unit    = "GB"
    }

    ecpu_per_second {
      maximum = 1000
    }
  }

  tags = {
    Name = "plane-valkey"
  }
}

resource "aws_security_group" "valkey" {
  name        = "plane-valkey-sg"
  description = "Security group for Plane Valkey"
  vpc_id      = var.vpc_id

  tags = {
    Name = "plane-valkey-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "valkey" {
  security_group_id            = aws_security_group.valkey.id
  referenced_security_group_id = var.eks_node_security_group_id

  from_port   = 6379
  to_port     = 6380
  ip_protocol = "tcp"

  description = "Allow Valkey access from EKS"
}