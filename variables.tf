/**
 * variables.tf - Unified variables for FusionOMS infrastructure
 *
 * This file declares all inputs required to deploy the FusionOMS stack
 * into different environments (localstack, staging, production, dev, etc.).
 * By adjusting these variables via tfvars files or CLI arguments you can
 * provision identical resources into any account or region. Defaults are
 * intentionally safe and suitable for local development when combined
 * with the LocalStack provider configuration in provider.tf.
 */

// General environment configuration
variable "environment" {
  description = "Environment name (e.g. localstack, staging, production, dev)"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  default     = "fusionoms"
}

variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

// Toggle LocalStack support.  When true the provider endpoints and
// credentials are configured to talk to a running LocalStack instance.
// See provider.tf for details.
variable "is_localstack" {
  description = "Enable LocalStack provider configuration"
  type        = bool
  default     = false
}

// URL of the LocalStack edge service.  Only used when is_localstack=true.
variable "localstack_endpoint" {
  description = "Base URL for LocalStack services"
  type        = string
  default     = "http://localhost:4566"
}

// VPC configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"// to protect existing vpc reserved bloc 
}

variable "availability_zones" {
  description = "Availability zones to spread resources across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

// RDS configuration
variable "db_instance_class" {
  description = "Instance class for the PostgreSQL database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database in GB"
  type        = number
  default     = 100
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "fusionOmsAdmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

variable "db_publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Backup retention period for RDS, in days"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployments for the database"
  type        = bool
  default     = false
}

variable "enable_rds_monitoring" {
  description = "Enable enhanced monitoring for the database"
  type        = bool
  default     = false
}

// ECS configuration
variable "ecs_task_cpu" {
  description = "CPU units allocated per ECS task for each service"
  type        = map(string)
  default = {
    frontend     = "256"
    backend      = "512"
    auth         = "256"
    projects_api = "256"
  }
}

variable "ecs_task_memory" {
  description = "Memory (in MB) allocated per ECS task for each service"
  type        = map(string)
  default = {
    frontend     = "512"
    backend      = "1024"
    auth         = "512"
    projects_api = "512"
  }
}

// Optional override for the ECS cluster name.  When left empty the
// cluster name will be derived from project_name and environment in
// locals.tf.  Set this when you need a specific cluster name.
variable "ecs_cluster_name" {
  description = "Override for ECS cluster name"
  type        = string
  default     = ""
}

// Application Load Balancer configuration
variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "alb_enable_http2" {
  description = "Enable HTTP/2 on the ALB"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path used by ALB health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval between ALB health checks, in seconds"
  type        = number
  default     = 30
}

// Domain and certificates
variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listeners"
  type        = string
  default     = ""
}

// Autoscaling configuration
variable "enable_autoscaling" {
  description = "Toggle ECS service autoscaling"
  type        = bool
  default     = false
}

/**
 * auth_jwt_secret - secret used by the authentication service to sign JWT
 * tokens.  It is marked sensitive so it does not appear in plan output.
 * Override this in your tfvars for staging/production environments.
 */
variable "auth_jwt_secret" {
  description = "Secret key for signing JSON Web Tokens"
  type        = string
  default     = "change-me-in-prod"
  sensitive   = true
}

/**
 * auth_database_name - logical database name used by the authentication
 * service.  This can differ from the main database name if you choose
 * to store auth data in a separate schema or database.  Override as
 * needed in tfvars.
 */
variable "auth_database_name" {
  description = "Database name used by the authentication service"
  type        = string
  default     = "fusionoms_auth"
}

/**
 * admin_cidr_for_rds - CIDR block allowed to directly access the database
 * security group (e.g. from a bastion host).  Use a single IP CIDR or
 * range.  Only used to populate a temporary ingress rule; remove or
 * restrict this in production.
 */
variable "admin_cidr_for_rds" {
  description = "CIDR allowed to access RDS directly for administration"
  type        = string
  default     = "184.145.32.155/32"
}

// Optional per-service subdomains used by ALB host-based routing.  You
// can override these values in your tfvars to match your DNS
// configuration.  They should contain fully qualified domain names.


variable "service_subdomains" {
  description = "Map of hostnames for each service (frontend, api, auth, projects)"
  type        = map(string)
  default = {
    frontend = "fusionoms.blackstarfusion.ca"
    api      = "api.fusionoms.blackstarfusion.ca"
    auth     = "auth.fusionoms.blackstarfusion.ca"
    projects = "project.fusionoms.blackstarfusion.ca"
  }
}

# just for testing


// Common tagging applied to all resources.  You can override or extend
// these tags via tfvars files.  'Environment' will be overwritten at
// runtime with the provided environment name.
variable "common_tags" {
  description = "Map of tags to apply to all AWS resources"
  type        = map(string)
  default = {
    Project   = "FusionOMS"
    ManagedBy = "Terraform"
    Purpose   = "FusionOMS-Stack"
  }
}


# for additional resources
# in variables.tf 
variable "enable_images_bucket" {
  description = "Whether to create the user images S3 bucket"
  type        = bool
  default     = false
}

variable "images_bucket_name" {
  description = "Override for the images bucket; leave blank to derive from project/env"
  type        = string
  default     = ""
}

variable "enable_images_cloudfront" {
  description = "Whether to create a CloudFront distribution in front of the images bucket"
  type        = bool
  default     = false
}

variable "images_aliases" {
  description = "List of alternate domain names (CNAMEs) for CloudFront (e.g. images.fusionoms.blackstarfusion.ca)"
  type        = list(string)
  default     = []
}

variable "images_acm_certificate_arn" {
  description = "ARN of the ACM certificate to use for CloudFront. Leave empty to use the default CloudFront certificate"
  type        = string
  default     = ""
}

variable "images_price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, or PriceClass_All)"
  type        = string
  default     = "PriceClass_All"
}

# Optional CORS configuration if direct browser uploads are needed
variable "images_cors_enabled" {
  description = "Enable CORS configuration on the images bucket"
  type        = bool
  default     = false
}

variable "images_cors_allowed_origins" {
  description = "Allowed origins for CORS (only used when images_cors_enabled = true)"
  type        = list(string)
  default     = []
}

variable "images_cors_allowed_methods" {
  description = "Allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "PUT", "POST", "DELETE"]
}

variable "images_cors_allowed_headers" {
  description = "Allowed headers for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "images_cors_expose_headers" {
  description = "Headers exposed by CORS"
  type        = list(string)
  default     = ["ETag"]
}