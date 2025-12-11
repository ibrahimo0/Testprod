# staging.example.tfvars - Example variables for staging environment

# Set the environment name.  This value is included in resource names and
# tags to keep staging resources separate from other environments.
environment = "staging"

# VPC CIDR should not overlap with other environments if they share the same
# AWS account.  Choose a unique range for each environment.
vpc_cidr = "10.2.0.0/16"

# Region to deploy into
region = "us-east-1"

# Database credentials
db_username = "fusionOmsAdmin"
db_password = "ChangeMe123!"

# Whether the RDS instance should be publicly accessible.  Set this to
# false in production for better security.
db_publicly_accessible = true

# JWT secret used by the authentication service.  Set this to a strong
# random value in real environments.
auth_jwt_secret = "change-me-in-staging"

# CIDR block allowed to connect directly to the database for
# administration.  Replace this with your bastion host IP or remove
# entirely for production.
admin_cidr_for_rds = "184.145.32.155/32"

# ACM certificate ARN for the ALB HTTPS listener.  Provide the ARN
# issued in the account for your domain.  Leave empty when using
# LocalStack.
acm_certificate_arn = "arn:aws:acm:us-east-1:xxxxxxxxxxxxxCHANGEwithACMcertificate"

# Per-service hostnames used by ALB routing.  Adjust to match your
# DNS zone.  Values must be fully qualified domain names (FQDNs).


service_subdomains = {
  frontend = "fusionoms.example.com"
  api      = "api.fusionoms.example.com"
  auth     = "auth.fusionoms.example.com"
  projects = "project.fusionoms.example.com"
}


# Tags applied to all resources in this environment
common_tags = {
  Project   = "FusionOMS"
  Environment = "Staging"
  ManagedBy = "Terraform"
  Purpose   = "FusionOMS-Testing"
}

# to add to our xxxx.tfvars ! 
enable_images_bucket      = true
enable_images_cloudfront  = true
#images_bucket_name        = "fusionoms-stagingTOCHANGEifyouwant-user-images"  # optional override
images_aliases           = []
images_acm_certificate_arn = ""  # use default CloudFront cert, if you have puchased your certificate put its ARN here
images_price_class       = "PriceClass_All"
#images_cors_enabled      = false # unless you need direct browser uploads
images_cors_enabled        = true
images_cors_allowed_origins = [
  "https://fusionoms.blackstarfusion.ca",
  "http://localhost:3000",
  "http://localhost:3001",
]
