bucket         = "fusionoms-terraform-state-9797987random" #change with your bucket name created in the bootstrap 
dynamodb_table = "fusionoms-terraform-locks" #change with dynamodb created during the bootstrap
region         = "us-east-1"
key            = "staging/terraform.tfstate" # for other environments just change the key, with dev/terraform.tfstate for a dev env
encrypt        = true
