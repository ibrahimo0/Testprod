/* PostgreSQL database configuration */

// Subnet groups
resource "aws_db_subnet_group" "public" {
  name        = "fusionoms-${var.environment}-public-db-subnet-group"
  description = "Public subnets for DB access (mirrors production)"
  subnet_ids  = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-public-db-subnet-group"
    Environment = var.environment
  })
}

resource "aws_db_subnet_group" "private" {
  name        = "fusionoms-${var.environment}-private-db-subnet-group"
  description = "Private subnets for the database"
  subnet_ids  = [aws_subnet.private_db_1a.id, aws_subnet.private_db_1b.id]

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-private-db-subnet-group"
    Environment = var.environment
  })
}

// Parameter group for PostgreSQL 17
resource "aws_db_parameter_group" "pg17" {
  name        = "fusionoms-${var.environment}-postgres17-params"
  family      = "postgres17"
  description = "Custom parameter group for PostgreSQL 17"

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-postgres17-params"
    Environment = var.environment
  })
}

// KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for encrypting RDS storage"
  deletion_window_in_days = 10

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-rds-kms-key"
    Environment = var.environment
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/fusionoms-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_instance" "db" {
  identifier          = "fusionoms-${var.environment}-db"
  instance_class      = var.db_instance_class
  engine              = "postgres"
  engine_version      = "17.4"
  allocated_storage   = var.db_allocated_storage
  db_name             = "fusionoms"  // logical database name inside PG
  username            = var.db_username
  password            = var.db_password
  storage_type        = "gp2"
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds.arn
  db_subnet_group_name = aws_db_subnet_group.public.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = var.db_publicly_accessible
  backup_retention_period = var.db_backup_retention_period
  multi_az                = var.db_multi_az
  maintenance_window      = "sun:07:00-sun:09:00"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot       = true
  deletion_protection         = false
  skip_final_snapshot         = true
  final_snapshot_identifier   = "fusionoms-${var.environment}-db-final-${formatdate("YYYYMMDDhhmm", timestamp())}"
  parameter_group_name        = aws_db_parameter_group.pg17.name

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-db"
    Environment = var.environment
    Component   = "Database"
  })

  depends_on = [aws_db_subnet_group.public, aws_security_group.db_sg]
}

// Outputs
output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL instance"
  value       = aws_db_instance.db.endpoint
}

output "rds_port" {
  description = "Port of the PostgreSQL instance"
  value       = aws_db_instance.db.port
}

output "rds_security_group_id" {
  description = "ID of the DB security group"
  value       = aws_security_group.db_sg.id
}