/* SSM Parameter Store configuration */

locals {
  # Root path for all parameters combining project name and environment.
  ssm_prefix = "/${var.project_name}/${var.environment}"
}

// ==================== Database Parameters ====================

resource "aws_ssm_parameter" "database_host" {
  name        = "${local.ssm_prefix}/database/host"
  description = "Host of the PostgreSQL database for ${var.project_name} in ${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.db.address
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/database/host"
    Environment = var.environment
    Component   = "Database"
  })
  depends_on = [aws_db_instance.db]
}

resource "aws_ssm_parameter" "database_port" {
  name        = "${local.ssm_prefix}/database/port"
  description = "Port for the PostgreSQL database"
  type        = "String"
  value       = tostring(aws_db_instance.db.port)
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/database/port"
    Environment = var.environment
    Component   = "Database"
  })
  depends_on = [aws_db_instance.db]
}

resource "aws_ssm_parameter" "database_name" {
  name        = "${local.ssm_prefix}/database/name"
  description = "Logical database name"
  type        = "String"
  value       = aws_db_instance.db.db_name
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/database/name"
    Environment = var.environment
    Component   = "Database"
  })
  depends_on = [aws_db_instance.db]
}

resource "aws_ssm_parameter" "database_username" {
  name        = "${local.ssm_prefix}/database/username"
  description = "Master username for the database"
  type        = "SecureString"
  value       = var.db_username
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/database/username"
    Environment = var.environment
    Component   = "Database"
  })
}

resource "aws_ssm_parameter" "database_password" {
  name        = "${local.ssm_prefix}/database/password"
  description = "Master password for the database"
  type        = "SecureString"
  value       = var.db_password
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/database/password"
    Environment = var.environment
    Component   = "Database"
  })
}

resource "aws_ssm_parameter" "database_connection_string" {
  name        = "${local.ssm_prefix}/database/connection-string"
  description = "Full PostgreSQL connection string"
  type        = "SecureString"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.db.address}:${aws_db_instance.db.port}/${aws_db_instance.db.db_name}"
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/database/connection-string"
    Environment = var.environment
    Component   = "Database"
  })
  depends_on = [aws_db_instance.db]
}

// ==================== Authentication Parameters ====================

resource "aws_ssm_parameter" "auth_database_name" {
  name        = "${local.ssm_prefix}/auth/database/name"
  description = "Database name used by the authentication service"
  type        = "String"
  value       = var.auth_database_name
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/auth/database/name"
    Environment = var.environment
    Component   = "Auth"
  })
}

resource "aws_ssm_parameter" "auth_jwt_secret" {
  name        = "${local.ssm_prefix}/auth/jwt-secret"
  description = "Secret used to sign JWTs for authentication"
  type        = "SecureString"
  value       = var.auth_jwt_secret
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/auth/jwt-secret"
    Environment = var.environment
    Component   = "Auth"
  })
}

// ==================== Backend and Frontend Parameters ====================

resource "aws_ssm_parameter" "backend_cors_origin" {
  name        = "${local.ssm_prefix}/backend/cors-origin"
  description = "Allowed CORS origin for the backend API"
  type        = "String"
  value       = "https://${aws_lb.main.dns_name}"
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/backend/cors-origin"
    Environment = var.environment
    Component   = "Backend"
  })
  depends_on = [aws_lb.main]
}

resource "aws_ssm_parameter" "backend_url" {
  name        = "${local.ssm_prefix}/backend/url"
  description = "Base URL of the backend API"
  type        = "String"
  value       = "https://${aws_lb.main.dns_name}"
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/backend/url"
    Environment = var.environment
    Component   = "Backend"
  })
  depends_on = [aws_lb.main]
}

resource "aws_ssm_parameter" "frontend_url" {
  name        = "${local.ssm_prefix}/frontend/url"
  description = "Base URL of the frontend application"
  type        = "String"
  value       = "https://${aws_lb.main.dns_name}"
  tags = merge(var.common_tags, {
    Name        = "${local.ssm_prefix}/frontend/url"
    Environment = var.environment
    Component   = "Frontend"
  })
  depends_on = [aws_lb.main]
}

// ==================== Outputs ====================

output "ssm_parameters" {
  description = "Paths of key SSM parameters"
  value = {
    database_host        = aws_ssm_parameter.database_host.name
    database_port        = aws_ssm_parameter.database_port.name
    database_name        = aws_ssm_parameter.database_name.name
    database_username    = aws_ssm_parameter.database_username.name
    database_password    = aws_ssm_parameter.database_password.name
    connection_string    = aws_ssm_parameter.database_connection_string.name
    auth_database_name   = aws_ssm_parameter.auth_database_name.name
    auth_jwt_secret      = aws_ssm_parameter.auth_jwt_secret.name
    backend_cors_origin  = aws_ssm_parameter.backend_cors_origin.name
    backend_url          = aws_ssm_parameter.backend_url.name
    frontend_url         = aws_ssm_parameter.frontend_url.name
  }
}