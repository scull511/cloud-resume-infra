data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/service-role/AWSLambdaBasicExecutionRole-52f1106f-32a8-4d0e-8906-207a15be314b"
}

resource "aws_iam_role" "lambda_exec" {
  name = "cloud-resume-counter-role-ltpb9qv8"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "cloud-resume-challenge"
  }
}

resource "aws_iam_role_policy" "dynamodb_update" {
  name = "dynamodb-update-cloud-resume-counter"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "dynamodb:UpdateItem"
        Resource = aws_dynamodb_table.counter.arn
      }
    ]
  })
}
