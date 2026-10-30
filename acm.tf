resource "aws_acm_certificate" "site" {
  provider          = aws.us_east_1
  domain_name       = "*.simoncull.co.uk"
  validation_method = "DNS"

  tags = {
    Project = "cloud-resume-challenge"
  }

  lifecycle {
    create_before_destroy = true
  }
}