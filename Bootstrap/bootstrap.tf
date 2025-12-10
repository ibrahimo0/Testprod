#to create backend resources to manage the coming statefile, to run before the main configuration

terraform {
  required_version = ">=1.5"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.0"
    }
  }


#for the backend use local state temporarily
backend "local" {
path = "bootstrap.tfstate"
}
}

provider "aws" {
 # access_key = "test"
 # secret_key = "test"
  region = "us-east-1"
  #skip_credentials_validation = true
  #skip_requesting_account_id = true
 # s3_use_path_style = true
/*
  endpoints {
    s3 = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }*/
  
}


#S3 for Terraform state
resource "aws_s3_bucket" "terraform_state" {
    bucket = "fusionoms-terraform-state-9797987random"
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks_fusionoms" {
    name = "fusionoms-terraform-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
      name = "LockID"
      type = "S"
    }
}
