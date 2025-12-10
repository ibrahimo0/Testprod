/* ECS cluster, task definitions and services */

// CloudWatch log groups for each service
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = {
    frontend = "/ecs/${local.name_prefix}-frontend"
    auth     = "/ecs/${local.name_prefix}-auth"
    backend  = "/ecs/${local.name_prefix}-backend"
    projects = "/ecs/${local.name_prefix}-projects"
  }
  name              = each.value
  retention_in_days = 30
  tags = merge(var.common_tags, {
    Name        = each.value
    Environment = var.environment
    Service     = each.key
  })
}

// ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = merge(var.common_tags, {
    Name        = local.ecs_cluster_name
    Environment = var.environment
  })
}

// Task Definitions
locals {
  // Build a common log configuration for reuse
  log_opts = { for svc in ["frontend", "auth", "backend", "projects"] : svc => {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs[svc].name
      "awslogs-region"        = var.region
      "awslogs-stream-prefix" = "ecs"
    }
  } }
}

// Frontend task definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "fusionoms-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["frontend"]
  memory                   = var.ecs_task_memory["frontend"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "fusionoms-${var.environment}-frontend-container"
      image = "${aws_ecr_repository.frontend.repository_url}:latest"
      portMappings = [ { containerPort = 80, protocol = "tcp" } ]
      environment = [
        { name = "REACT_APP_API_URL", value = "https://${aws_lb.main.dns_name}" }
      ]
      logConfiguration = local.log_opts["frontend"]
      essential = true
    }
  ])
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-frontend-task"
    Environment = var.environment
    Service     = "Frontend"
  })
}

// Auth API task definition
resource "aws_ecs_task_definition" "auth" {
  family                   = "fusionoms-${var.environment}-auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["auth"]
  memory                   = var.ecs_task_memory["auth"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "fusionoms-${var.environment}-auth-container"
      image = "${aws_ecr_repository.auth.repository_url}:latest"
      portMappings = [ { containerPort = 5127, protocol = "tcp" } ]
      environment = [ { name = "NODE_ENV", value = "production" } ]
      secrets = [
        { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_connection_string.arn },
        { name = "JWT_SECRET",   valueFrom = aws_ssm_parameter.auth_jwt_secret.arn }
      ]
      logConfiguration = local.log_opts["auth"]
      essential = true
    }
  ])
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-auth-task"
    Environment = var.environment
    Service     = "Auth-API"
  })
}

// Backend API task definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "fusionoms-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["backend"]
  memory                   = var.ecs_task_memory["backend"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name  = "fusionoms-${var.environment}-backend-container"
      image = "${aws_ecr_repository.backend.repository_url}:latest"
      portMappings = [ { containerPort = 5152, protocol = "tcp" } ]
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "CORS_ORIGIN", value = "https://${aws_lb.main.dns_name}" }
      ]
      secrets = [ { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_connection_string.arn } ]
      logConfiguration = local.log_opts["backend"]
      essential = true
    }
  ])
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-backend-task"
    Environment = var.environment
    Service     = "Backend-API"
  })
}

// Projects API task definition
resource "aws_ecs_task_definition" "projects" {
  family                   = "fusionoms-${var.environment}-projects-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["projects_api"]
  memory                   = var.ecs_task_memory["projects_api"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name  = "fusionoms-${var.environment}-projects-container"
      image = "${aws_ecr_repository.projects.repository_url}:latest"
      portMappings = [ { containerPort = 5092, protocol = "tcp" } ]
      environment = [ { name = "NODE_ENV", value = "production" } ]
      secrets = [ { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_connection_string.arn } ]
      logConfiguration = local.log_opts["projects"]
      essential = true
    }
  ])
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-projects-task"
    Environment = var.environment
    Service     = "Projects-API"
  })
}

// ECS Services
resource "aws_ecs_service" "frontend" {
  name            = "fusionoms-${var.environment}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  network_configuration {
    subnets          = [aws_subnet.private_ecs_1a.id, aws_subnet.private_ecs_1b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "fusionoms-${var.environment}-frontend-container"
    container_port   = 80
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  enable_execute_command = true
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-frontend-service"
    Environment = var.environment
    Service     = "Frontend"
  })
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

resource "aws_ecs_service" "auth" {
  name            = "fusionoms-${var.environment}-auth-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  network_configuration {
    subnets = [aws_subnet.private_db_1a.id, aws_subnet.private_db_1b.id, aws_subnet.private_ecs_1a.id, aws_subnet.private_ecs_1b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name   = "fusionoms-${var.environment}-auth-container"
    container_port   = 5127
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  enable_execute_command = true
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-auth-service"
    Environment = var.environment
    Service     = "Auth-API"
  })
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

resource "aws_ecs_service" "backend" {
  name            = "fusionoms-${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  network_configuration {
    subnets          = [aws_subnet.private_ecs_1a.id, aws_subnet.private_ecs_1b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "fusionoms-${var.environment}-backend-container"
    container_port   = 5152
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  enable_execute_command = true
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-backend-service"
    Environment = var.environment
    Service     = "Backend-API"
  })
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

resource "aws_ecs_service" "projects" {
  name            = "fusionoms-${var.environment}-projects-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.projects.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  network_configuration {
    subnets          = [aws_subnet.private_ecs_1a.id, aws_subnet.private_ecs_1b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.projects_api.arn
    container_name   = "fusionoms-${var.environment}-projects-container"
    container_port   = 5092
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  enable_execute_command = true
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-projects-service"
    Environment = var.environment
    Service     = "Projects-API"
  })
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

// Autoscaling (optional)
resource "aws_appautoscaling_target" "frontend" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "FusionOMS-${var.environment}-frontend-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.frontend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend[0].service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

// Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_ids" {
  description = "IDs of ECS services"
  value = {
    frontend = aws_ecs_service.frontend.id
    auth     = aws_ecs_service.auth.id
    backend  = aws_ecs_service.backend.id
    projects = aws_ecs_service.projects.id
  }
}
