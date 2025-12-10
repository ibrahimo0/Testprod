/* Security groups for ALB, ECS and PostgreSQL */

// ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "fusionoms-${var.environment}-alb-sg"
  description = "Security group for FusionOMS ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-alb-sg"
    Environment = var.environment
    Tier        = "LoadBalancer"
  })
}

// ECS Service Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "fusionoms-${var.environment}-ecs-sg"
  description = "Security group for FusionOMS ECS services"
  vpc_id      = aws_vpc.main.id

  // Frontend (HTTP) from ALB
  ingress {
    description     = "Frontend HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  // Projects API from ALB (port 5092)
  ingress {
    description     = "Projects API"
    from_port       = 5092
    to_port         = 5092
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  // Auth API from ALB (port 5127)
  ingress {
    description     = "Auth API"
    from_port       = 5127
    to_port         = 5127
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  // Backend API from ALB (port 5152)
  ingress {
    description     = "Backend API"
    from_port       = 5152
    to_port         = 5152
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-ecs-sg"
    Environment = var.environment
    Tier        = "Application"
  })
}

// RDS Security Group
resource "aws_security_group" "db_sg" {
  name        = "fusionoms-${var.environment}-db-sg"
  description = "Security group for FusionOMS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  // PostgreSQL from ECS services
  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  // Temporary specific IP allowlist (override via tfvars).  Use
  // var.admin_cidr_for_rds to specify your own bastion or admin IP.
  ingress {
    description = "Temporary access from admin IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr_for_rds]
  }

  // Temporary wide open ingress (should be disabled in production)
  ingress {
    description = "Temporary open access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-db-sg"
    Environment = var.environment
    Tier        = "Database"
  })
}

// Optional default security group – included for parity with production
resource "aws_security_group" "default_fusionoms" {
  name        = "fusionoms-${var.environment}-default-sg"
  description = "Default VPC security group allowing all internal traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-default-sg"
    Environment = var.environment
    Tier        = "Default"
  })
}
