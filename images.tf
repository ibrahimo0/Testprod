
# to add in locals.terraform 
  
locals {
  images_bucket_name = var.images_bucket_name != "" ? var.images_bucket_name : "${local.name_prefix}-user-images"
}


# S3 and cloudFront
resource "aws_s3_bucket" "images" {
  count         = var.enable_images_bucket ? 1 : 0
  bucket        = local.images_bucket_name
  force_destroy = true

  tags = merge(var.common_tags, {
    Name        = local.images_bucket_name
    Environment = var.environment
    Type        = "Images"
  })
}

resource "aws_s3_bucket_public_access_block" "images" {
  count  = var.enable_images_bucket ? 1 : 0
  bucket = aws_s3_bucket.images[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "images" {
  count     = var.enable_images_bucket && var.enable_images_cloudfront ? 1 : 0
  name      = "${local.name_prefix}-images-oac"
  description = "OAC for images bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "images" {
  count   = var.enable_images_bucket && var.enable_images_cloudfront ? 1 : 0
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.images[0].bucket_regional_domain_name
    origin_id                = "s3-images-${local.name_prefix}"
    origin_access_control_id = aws_cloudfront_origin_access_control.images[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-images-${local.name_prefix}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

    price_class = var.images_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn         = var.images_acm_certificate_arn != "" ? var.images_acm_certificate_arn : null
    cloudfront_default_certificate = var.images_acm_certificate_arn == ""
    ssl_support_method          = var.images_acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version    = "TLSv1.2_2021"
  }

  #viewer_certificate {
  #  cloudfront_default_certificate = true
 # }
   aliases = var.images_aliases


  tags = merge(var.common_tags, {
    Name        = "${local.name_prefix}-images-cdn"
    Environment = var.environment
    Type        = "Images-CDN"
  })
}


resource "aws_iam_policy" "images_s3_access" {
  count = var.enable_images_bucket ? 1 : 0
  name  = "${local.name_prefix}-images-s3-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      Resource = [
        aws_s3_bucket.images[0].arn,
        "${aws_s3_bucket.images[0].arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_images_s3_policy" {
  count      = var.enable_images_bucket ? 1 : 0
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.images_s3_access[0].arn
}


# to outputs.tf 
output "images_bucket_name" {
  description = "Images S3 bucket"
  value       = length(aws_s3_bucket.images) > 0 ? aws_s3_bucket.images[0].id : null

}

output "images_cloudfront_domain" {
  description = "CloudFront domain for images"
   value       = length(aws_cloudfront_distribution.images) > 0 ? aws_cloudfront_distribution.images[0].domain_name : null
}


# Optional CORS configuration 
resource "aws_s3_bucket_cors_configuration" "images" {
  count = var.enable_images_bucket && var.images_cors_enabled && length(var.images_cors_allowed_origins) > 0 ? 1 : 0
  bucket = aws_s3_bucket.images[0].id

  cors_rule {
    allowed_methods = var.images_cors_allowed_methods
    allowed_origins = var.images_cors_allowed_origins
    allowed_headers = var.images_cors_allowed_headers
    expose_headers  = var.images_cors_expose_headers
   
    #max_age_seconds = 3000
  }
}

# Bucket policy to allow CloudFront to read objects
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "images_policy" {
  count = var.enable_images_bucket && var.enable_images_cloudfront ? 1 : 0

  statement {
    sid    = "AllowCloudFrontRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = [
      aws_s3_bucket.images[0].arn,
      "${aws_s3_bucket.images[0].arn}/*"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.images[0].id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "images" {
  count  = var.enable_images_bucket && var.enable_images_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.images[0].id
  policy = data.aws_iam_policy_document.images_policy[0].json
}

