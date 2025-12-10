# localstack.example.tfvars - Example variables for local development

# LocalStack environment
environment   = "localstack"
is_localstack = true

# Region (has no effect on LocalStack beyond naming)
region = "us-east-1"

# VPC CIDR for LocalStack.  The VPC is only simulated in LocalStack and
# will not conflict with real AWS networks.  Still set a value for
# consistency.
vpc_cidr = "10.4.0.0/16"

# Database credentials (fake values for local testing)
db_username = "fusionOmsAdmin"
db_password = "localstack"
db_publicly_accessible = true

# JWT secret for auth service.  Use any value for local testing.
auth_jwt_secret = "localstack-secret"

# Admin CIDR isn't used with LocalStack, but must be set.
admin_cidr_for_rds = "0.0.0.0/0"

# Use path-style addressing for S3 and dummy ACM ARN (ignored in LocalStack)
acm_certificate_arn = ""

# Local hostnames (not used by LocalStack).  You can leave them as
# placeholders.  They will not be validated or routed.
service_subdomains = {
  frontend = "localhost"
  api      = "localhost"
  auth     = "localhost"
  projects = "localhost"
}

# Tags for local development
common_tags = {
  Project     = "FusionOMS"
  Environment = "LocalStack"
  ManagedBy   = "Terraform"
  Purpose     = "FusionOMS-Dev"
}

enable_images_bucket      = true
enable_images_cloudfront  = false 
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