variable "app_name" {
  type = string
}


variable "homepage_https_url" {
  type = string
}

variable "lambda_get_game_stacks_uri" {
  type = string
}

resource "aws_api_gateway_rest_api" "api" {

  name = "api-${var.app_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

}


resource "aws_api_gateway_resource" "resource" {

  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.app_name
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"


}

resource "aws_api_gateway_integration" "integration_get_game_stacks" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_get_game_stacks_uri
}
