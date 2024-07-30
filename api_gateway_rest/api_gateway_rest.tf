
variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}


variable "homepage_https_url" {
  type = string
}

variable "lambda_get_game_stacks_uri" {
  type = string
}

variable "lambda_get_game_stacks_name" {
  type = string
}

## CloudWatch
resource "aws_cloudwatch_log_group" "game_stacks_api_log_group" {
  name = "/aws/lambda/${var.lambda_get_game_stacks_name}"
}

## API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "api-${var.app_name}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id

  name        = "stage-${var.app_name}"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.game_stacks_api_log_group.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "integration_get_game_stacks" {
  api_id = aws_apigatewayv2_api.api.id

  integration_uri    = var.lambda_get_game_stacks_uri
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "route_get_game_stacks" {
  api_id = aws_apigatewayv2_api.api.id

  route_key = "GET /gamestacks"
  target    = "integrations/${aws_apigatewayv2_integration.integration_get_game_stacks.id}"
}

resource "aws_lambda_permission" "permission_get_game_stacks" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_get_game_stacks_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.stage.invoke_url
}

# resource "aws_api_gateway_rest_api" "api" {

#   name = "api-${var.app_name}"

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }

# }


# resource "aws_api_gateway_resource" "resource" {

#   rest_api_id = aws_api_gateway_rest_api.api.id
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   path_part   = var.app_name
# }

# resource "aws_api_gateway_method" "method" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.resource.id
#   http_method   = "ANY"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "integration_get_game_stacks" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.resource.id
#   http_method = aws_api_gateway_method.method.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = var.lambda_get_game_stacks_uri
# }

# resource "aws_lambda_permission" "apigw_lambda_get_game_stacks" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = var.lambda_get_game_stacks_name
#   principal     = "apigateway.amazonaws.com"

#   # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
#   source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"

# }
