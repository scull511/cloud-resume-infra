# Package the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "view_counter" {
  function_name     = "cloud-resume-counter"
  role              = aws_iam_role.lambda_exec.arn
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.14"
  filename          = data.archive_file.lambda_zip.output_path
  source_code_hash  = data.archive_file.lambda_zip.output_base64sha256
  timeout           = 3
  memory_size       = 128

  tags = {
    Project = "cloud-resume-challenge"
  }
}