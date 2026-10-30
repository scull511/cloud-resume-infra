resource "aws_apigatewayv2_api" "counter_api" {
  name          = "cloud-resume-counter-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [ 
      "https://cv.simoncull.co.uk",
      "https://www.simoncull.co.uk",
      "http://localhost:4321"
    ]
    allow_methods = ["GET"]
    allow_headers = []
  }

  tags = {
    Project = "cloud-resume-challenge"
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.counter_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.view_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_views" {
  api_id    = aws_apigatewayv2_api.counter_api.id
  route_key = "GET /views"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.counter_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.view_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.counter_api.execution_arn}/*/*"
}