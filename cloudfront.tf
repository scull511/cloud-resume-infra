resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "cv-simoncull-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["cv.simoncull.co.uk", "www.simoncull.co.uk"]
  price_class         = "PriceClass_All"

  origin {
    domain_name              = "cv.simoncull.co.uk.s3.eu-west-2.amazonaws.com"
    origin_id                = "cv-simoncull-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "cv-simoncull-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.index_rewrite.arn
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Project = "cloud-resume-challenge"
  }
}

resource "aws_cloudfront_function" "index_rewrite" {
  name    = "cv-simoncull-index-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Append index.html to directory-style URLs"
  publish = true
  code    = file("${path.module}/functions/index-rewrite.js")
}