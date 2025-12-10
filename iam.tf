/* IAM roles and policies */

// Execution role: used by ECS/Fargate to pull images and write logs
resource "aws_iam_role" "ecs_execution_role" {
  name        = "fusionoms-${var.environment}-ecs-execution-role"
  description = "ECS task execution role for FusionOMS"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-ecs-execution-role",
    Environment = var.environment,
    Type        = "ECS-Execution"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_custom" {
  name = "fusionoms-${var.environment}-ecs-execution-custom-policy"
  role = aws_iam_role.ecs_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ECRAccess",
        Effect = "Allow",
        Action = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"],
        Resource = "*"
      },
      {
        Sid    = "SSMParameterAccess",
        Effect = "Allow",
        Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
        Resource = "arn:aws:ssm:${var.region}:*:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Sid    = "KMSDecrypt",
        Effect = "Allow",
        Action = ["kms:Decrypt", "kms:DescribeKey"],
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs",
        Effect = "Allow",
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:${var.region}:*:*"
      }
    ]
  })
}

// Task role: used by the application code running inside containers
resource "aws_iam_role" "ecs_task_role" {
  name        = "fusionoms-${var.environment}-ecs-task-role"
  description = "ECS task role for FusionOMS runtime"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-ecs-task-role",
    Environment = var.environment,
    Type        = "ECS-Task"
  })
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "fusionoms-${var.environment}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "S3Access",
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::fusionoms-*",
          "arn:aws:s3:::fusionoms-*/*"
        ]
      },
      {
        Sid    = "SSMParameterReadAccess",
        Effect = "Allow",
        Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
        Resource = "arn:aws:ssm:${var.region}:*:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Sid    = "CloudWatchMetrics",
        Effect = "Allow",
        Action = ["cloudwatch:PutMetricData"],
        Resource = "*"
      },
      {
        Sid    = "XRayTracing",
        Effect = "Allow",
        Action = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"],
        Resource = "*"
      }
    ]
  })
}

// Optional monitoring role for RDS enhanced monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  count              = var.enable_rds_monitoring ? 1 : 0
  name               = "fusionoms-${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "monitoring.rds.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-rds-monitoring-role",
    Environment = var.environment,
    Type        = "RDS-Monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  count      = var.enable_rds_monitoring ? 1 : 0
  role       = aws_iam_role.rds_monitoring_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
