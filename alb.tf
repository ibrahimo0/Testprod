# Application Load Balancer configuration
// Target groups
resource "aws_lb_target_group" "frontend" {
  name        = "fusionoms-${var.environment}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-frontend-tg",
    Environment = var.environment,
    Service     = "Frontend"
  })
}

resource "aws_lb_target_group" "auth" {
  name        = "fusionoms-${var.environment}-auth-tg-5127"
  port        = 5127
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-auth-tg-5127",
    Environment = var.environment,
    Service     = "Auth-API"
  })
}

resource "aws_lb_target_group" "backend" {
  name        = "fusionoms-${var.environment}-backend-tg"
  port        = 5152
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-backend-tg-5152",
    Environment = var.environment,
    Service     = "Backend-API"
  })
}

resource "aws_lb_target_group" "projects_api" {
  name        = "fusionoms-${var.environment}-projectsapi-tg"
  port        = 5092
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-projectsapi-tg-5092",
    Environment = var.environment,
    Service     = "Projects-API"
  })
}

// Unused legacy backend group (5000) maintained for completeness
/*
resource "aws_lb_target_group" "backend_unused_unified" {
  name        = "fusionoms-${var.environment}-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
  }
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-backend-tg-5000",
    Environment = var.environment,
    Service     = "Backend-Unused"
  })
}
*/
// Application load balancer
resource "aws_lb" "main" {
  name               = "fusionoms-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
  enable_deletion_protection = var.alb_enable_deletion_protection
  enable_http2               = var.alb_enable_http2
  tags = merge(var.common_tags, {
    Name        = "fusionoms-${var.environment}-alb",
    Environment = var.environment
  })
}

// HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

// HTTPS listener 
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

// Listener rules for HTTP
resource "aws_lb_listener_rule" "http_auth_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }
  condition {
    path_pattern { values = ["/api/auth/*"] }
  }
}

resource "aws_lb_listener_rule" "http_api_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern { values = ["/api/*"] }
  }
}

resource "aws_lb_listener_rule" "http_project_api_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.projects_api.arn
  }
  condition {
    path_pattern { values = ["/project-api/*"] }
  }
}

// Host-based rules for HTTPS
resource "aws_lb_listener_rule" "https_auth_host" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 5
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }
  condition {
    host_header { values = [var.service_subdomains["auth"]] }
  }
}

resource "aws_lb_listener_rule" "https_api_host" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    host_header { values = [var.service_subdomains["api"]] }
  }
}

resource "aws_lb_listener_rule" "https_project_host" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 15
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.projects_api.arn
  }
  condition {
    host_header { values = [var.service_subdomains["projects"]] }
  }
}

// Path rules for HTTPS
resource "aws_lb_listener_rule" "https_auth_path" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }
  condition {
    path_pattern { values = ["/api/auth/*"] }
  }
}

resource "aws_lb_listener_rule" "https_api_path" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern { values = ["/api/*"] }
  }
}

resource "aws_lb_listener_rule" "https_project_api_path" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.projects_api.arn
  }
  condition {
    path_pattern { values = ["/project-api/*"] }
  }
}

// Outputs
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "target_group_arns" {
  description = "Map of all target group ARNs"
  value = {
    frontend     = aws_lb_target_group.frontend.arn
    auth         = aws_lb_target_group.auth.arn
    backend      = aws_lb_target_group.backend.arn
    projects_api = aws_lb_target_group.projects_api.arn
  }
}
