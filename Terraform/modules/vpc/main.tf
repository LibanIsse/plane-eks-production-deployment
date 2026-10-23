resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "plane-eks-vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = ["eu-west-2a", "eu-west-2b"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "plane-eks-public-${count.index + 1}"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = ["eu-west-2a", "eu-west-2b"][count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "plane-eks-private-${count.index + 1}"
  }
}

# Private subnets for RDS PostgreSQL
resource "aws_subnet" "database" {
  count = length(var.database_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.database_subnets[count.index]
  availability_zone       = ["eu-west-2a", "eu-west-2b"][count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "plane-eks-database-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "plane-eks-igw"
  }
}

# Public rt
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "plane-eks-public-rt"
  }
}

# Rt public traffic to the Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate both
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "plane-eks-nat-eip"
  }
}

# NAT Gateway for private EKS subnets
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "plane-eks-nat"
  }
}

# Private route table for EKS
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "plane-eks-private-rt"
  }
}

# Outbound internet access through NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# Associate private EKS subnets with the route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Rt database subnets
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "plane-eks-database-rt"
  }
}

# Associate database subnets with database route table
resource "aws_route_table_association" "database" {
  count = length(var.database_subnets)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.eu-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "plane-eks-s3-endpoint"
  }
}