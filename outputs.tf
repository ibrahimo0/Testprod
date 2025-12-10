/* Consolidated outputs */



output "subnet_ids" {
  description = "IDs of the key subnets used by the services"
  value = {
    public_1a      = aws_subnet.public_1a.id
    public_1b      = aws_subnet.public_1b.id
    private_ecs_1a = aws_subnet.private_ecs_1a.id
    private_ecs_1b = aws_subnet.private_ecs_1b.id
    private_db_1a  = aws_subnet.private_db_1a.id
    private_db_1b  = aws_subnet.private_db_1b.id
  }
}


output "ecs_service_names" {
  description = "Names of the ECS services"
  value = {
    frontend = aws_ecs_service.frontend.name
    auth     = aws_ecs_service.auth.name
    backend  = aws_ecs_service.backend.name
    projects = aws_ecs_service.projects.name
  }
}

// ECR repository URIs
output "ecr_repository_urls" {
  description = "URI of each ECR repository"
  value = {
    frontend = aws_ecr_repository.frontend.repository_url
    auth     = aws_ecr_repository.auth.repository_url
    backend  = aws_ecr_repository.backend.repository_url
    projects = aws_ecr_repository.projects.repository_url
  }
}

// RDS endpoint
output "database_endpoint" {
  description = "Hostname of the PostgreSQL instance"
  value       = aws_db_instance.db.address
}

output "database_port" {
  description = "Port for the PostgreSQL instance"
  value       = aws_db_instance.db.port
}

// SSM prefix for this environment
output "ssm_prefix" {
  description = "Root prefix for all SSM parameters created by this stack"
  value       = local.ssm_prefix
}