bucket         = "localstack-state"     # any name; LocalStack will simulate it
key            = "localstack/terraform.tfstate"
endpoint       = "http://localhost:4566"
skip_credentials_validation = true
skip_metadata_api_check     = true
force_path_style           = true