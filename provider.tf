/* AWS provider configuration for real AWS and LocalStack */

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


backend "s3" {
    # Leave this empty - values will come from -backend-config
  }
}

provider "aws" {
  # Always specify the region via a variable
  region = var.region

  # When targeting LocalStack we supply dummy credentials and skip
  # authentication/metadata checks. When targeting real AWS the
  # provider picks up credentials from the usual sources
  access_key                  = var.is_localstack ? "test" : null
  secret_key                  = var.is_localstack ? "test" : null
  skip_credentials_validation = var.is_localstack
  skip_metadata_api_check     = var.is_localstack
  s3_use_path_style           = var.is_localstack

  # Configure custom service endpoints only when running against
  # LocalStack. The dynamic block ensures that the `endpoints` block
  # is omitted entirely for real AWS deployments. For a full list of
  # service keys see the AWS provider documentation【818644791916587†screenshot】.  All
  # endpoints are pointed at the single LocalStack edge URL.
  dynamic "endpoints" {
    for_each = var.is_localstack ? [1] : []
    content {
      acm            = var.localstack_endpoint
      dynamodb       = var.localstack_endpoint
      ec2            = var.localstack_endpoint
      ecs            = var.localstack_endpoint
      elasticloadbalancing = var.localstack_endpoint
      elbv2          = var.localstack_endpoint
      iam            = var.localstack_endpoint
      kms            = var.localstack_endpoint
      logs           = var.localstack_endpoint
      rds            = var.localstack_endpoint
      route53        = var.localstack_endpoint
      s3             = var.localstack_endpoint
      secretsmanager = var.localstack_endpoint
      ssm            = var.localstack_endpoint
      ecr = var.localstack_endpoint
  
    }
  }
}
