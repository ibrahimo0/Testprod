/* ECR repositories for the services */

resource "aws_ecr_repository" "frontend" {
  name                 = "fusionoms-web"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration { scan_on_push = false }
  encryption_configuration { encryption_type = "AES256" }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-web"
    Service     = "Frontend"
    Environment = var.environment
  })
}

resource "aws_ecr_repository" "auth" {
  name                 = "fusionoms-auth"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = false }
  encryption_configuration { encryption_type = "AES256" }
  tags = merge(var.common_tags, {
    Name        = "fusionoms-auth"
    Service     = "Auth-API"
    Environment = var.environment
  })
}

resource "aws_ecr_repository" "backend" {
  name                 = "fusionoms-api"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = false }
  encryption_configuration { encryption_type = "AES256" }
  tags = merge(var.common_tags, {
    Name        = "fusionoms-api"
    Service     = "Backend-API"
    Environment = var.environment
  })
}

resource "aws_ecr_repository" "projects" {
  name                 = "fusionoms-projectapi"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = false }
  encryption_configuration { encryption_type = "AES256" }
  tags = merge(var.common_tags, {
    Name        = "fusionoms-projectapi"
    Service     = "Projects-API"
    Environment = var.environment
  })
}

// Optionally add lifecycle policies to limit old images
resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = jsonencode({ rules = [{ rulePriority = 1, description = "Keep last 10 images", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }, action = { type = "expire" } }] })
}

resource "aws_ecr_lifecycle_policy" "auth" {
  repository = aws_ecr_repository.auth.name
  policy     = jsonencode({ rules = [{ rulePriority = 1, description = "Keep last 10 images", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }, action = { type = "expire" } }] })
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy     = jsonencode({ rules = [{ rulePriority = 1, description = "Keep last 10 images", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }, action = { type = "expire" } }] })
}

resource "aws_ecr_lifecycle_policy" "projects" {
  repository = aws_ecr_repository.projects.name
  policy     = jsonencode({ rules = [{ rulePriority = 1, description = "Keep last 10 images", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }, action = { type = "expire" } }] })
}

output "ecr_repositories" {
  description = "Map of ECR repository URIs by service"
  value = {
    frontend = aws_ecr_repository.frontend.repository_url
    auth     = aws_ecr_repository.auth.repository_url
    backend  = aws_ecr_repository.backend.repository_url
    projects = aws_ecr_repository.projects.repository_url
  }
}
