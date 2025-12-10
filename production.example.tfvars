# production.example.tfvars - Example variables for production environment

# Set the environment name.  This value is included in resource names and
# tags to keep production resources distinct from staging or dev.
environment = "production"

# VPC CIDR for production.  Ensure this does not overlap with any
# other environment if using a single AWS account.  Use a unique CIDR
# block per environment.
vpc_cidr = "10.1.0.0/16"

# Region to deploy into
region = "us-east-1"

# Database credentials
db_username = "fusionOmsAdmin"
db_password = "ChangeMe123!"

# For production, we typically set the RDS to not be publicly accessible.
db_publicly_accessible = false

# JWT secret used by the authentication service.  Replace this with a
# strong, securely stored secret before deploying.
auth_jwt_secret = "replace-with-strong-secret"

# Admin CIDR for direct database access.  Limit this to your bastion or
# office IP range, or omit entirely by leaving it empty.
admin_cidr_for_rds = "192.0.2.0/32"

# ACM certificate ARN for production.  Use a real certificate for your
# domain.  Leave empty if not using HTTPS.
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/replace-with-prod-cert"

# Per-service hostnames used by ALB routing in production.  Adjust to
# your actual domain names.
service_subdomains = {
  frontend = "fusionoms.prod.example.com"
  api      = "api.fusionoms.prod.example.com"
  auth     = "auth.fusionoms.prod.example.com"
  projects = "project.fusionoms.prod.example.com"
}

# Common tags for production resources
common_tags = {
  Project     = "FusionOMS"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Purpose     = "FusionOMS-Prod"
}

# for prod images_bucket_name       = "fusionoms-production-task-images1124"  # optional
# for prod images_aliases           = ["images.fusionoms.blackstarfusion.ca"]


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
