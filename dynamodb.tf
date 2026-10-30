resource "aws_dynamodb_table" "counter" {
  name           = "cloud-resume-counter"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "cloud-resume-challenge"
  }
}
