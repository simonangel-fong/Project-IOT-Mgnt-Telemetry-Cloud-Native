# variable
locals {
  aws_cf_origin_api = "${var.project}-${var.env}-origin-api"
  aws_cf_origin_web = "${var.project}-${var.env}-origin-web"
}



# ###############################
# CloudFront
# ###############################
resource "aws_cloudfront_distribution" "cdn" {

  enabled             = true
  aliases             = [local.dns_record] # e.g. iot-dev.arguswatcher.net
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  # ORIGIN: ALB (API)
  origin {
    origin_id   = "${var.project}-${var.env}-cf-origin-alb"
    domain_name = aws_lb.alb.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # DEFAULT CACHE BEHAVIOR
  default_cache_behavior {
    target_origin_id       = "${var.project}-${var.env}-cf-origin-alb"
    viewer_protocol_policy = "redirect-to-https"

    # API needs all methods
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    compress        = true

    # No caching for API
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true

      headers = [
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "x-api-key",
        "Authorization",
      ]

      cookies {
        forward = "none"
      }
    }
  }

  # logging
  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    include_cookies = false
    prefix          = "${var.project}/${var.env}/cloudfront/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  http_version = "http2and3"

  tags = {
    Name = "${var.project}-${var.env}-cloudfront"
  }
}
