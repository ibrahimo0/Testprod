/* VPC, subnets and networking */

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-vpc"
    Environment = var.environment
    test = "github actions test tag !"
    secondtest = "second"
    fourthtag = "this time"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-igw"
    Environment = var.environment
  })
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-nat-eip"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1a.id

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-nat"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.igw]
}

// === Subnets ===

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1) // 10.x.1.0/24
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-public1-${var.availability_zones[0]}"
    Environment = var.environment
    Type        = "Public"
  })
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2) // 10.x.2.0/24
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-public2-${var.availability_zones[1]}"
    Environment = var.environment
    Type        = "Public"
  })
}

resource "aws_subnet" "private_ecs_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 10) // 10.x.10.0/24
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-private-ecs1-${var.availability_zones[0]}"
    Environment = var.environment
    Type        = "Private-ECS"
  })
}

resource "aws_subnet" "private_ecs_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 11) // 10.x.11.0/24
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-private-ecs2-${var.availability_zones[1]}"
    Environment = var.environment
    Type        = "Private-ECS"
  })
}

resource "aws_subnet" "private_db_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 20) // 10.x.20.0/24
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-private-db1-${var.availability_zones[0]}"
    Environment = var.environment
    Type        = "Private-DB"
  })
}

resource "aws_subnet" "private_db_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 21) // 10.x.21.0/24
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-private-db2-${var.availability_zones[1]}"
    Environment = var.environment
    Type        = "Private-DB"
  })
}

// === Route Tables ===

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-public-rtb"
    Environment = var.environment
    Type        = "Public"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-private-rtb"
    Environment = var.environment
    Type        = "Private"
  })
}

// === Route Table Associations ===

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_ecs_1a" {
  subnet_id      = aws_subnet.private_ecs_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_ecs_1b" {
  subnet_id      = aws_subnet.private_ecs_1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db_1a" {
  subnet_id      = aws_subnet.private_db_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db_1b" {
  subnet_id      = aws_subnet.private_db_1b.id
  route_table_id = aws_route_table.private.id
}

// === Outputs ===

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
}

output "private_ecs_subnet_ids" {
  description = "IDs of private ECS subnets"
  value       = [aws_subnet.private_ecs_1a.id, aws_subnet.private_ecs_1b.id]
}

output "private_db_subnet_ids" {
  description = "IDs of private DB subnets"
  value       = [aws_subnet.private_db_1a.id, aws_subnet.private_db_1b.id]
}
