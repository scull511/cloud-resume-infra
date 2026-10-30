resource "aws_route53_zone" "main" {
  name = "simoncull.co.uk"

  tags = {
    Project = "cloud-resume-challenge"
  }
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "simoncull.co.uk"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cv" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cv.simoncull.co.uk"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.simoncull.co.uk"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_8344b273110bf73427432aad730c6936.simoncull.co.uk"
  type    = "CNAME"
  ttl     = 300
  records = ["_77d071c0d1f1a0ba4ce506085508cdf5.mhbtsbpdnt.acm-validations.aws."]
}