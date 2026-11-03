resource "aws_db_subnet_group" "main" {
  name       = "plane-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "plane-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "plane-rds-sg"
  description = "Security group for Plane PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "plane-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.eks_node_security_group_id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  description = "Allow PostgreSQL access from EKS nodes"
}

resource "aws_db_instance" "main" {
  identifier = "plane-postgres"

  engine         = "postgres"
  engine_version = "16.15"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = "planeadmin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Name = "plane-postgres"
  }
}