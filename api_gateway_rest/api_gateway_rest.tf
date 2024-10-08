
variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "subdomain_api" {
  type = string
}

variable "hosted_zone_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "subdomain_homepage" {
  type = string
}

variable "homepage_branch" {
  type = string
}

variable "lambda_get_game_stacks_uri" {
  type = string
}

variable "lambda_get_game_stacks_name" {
  type = string
}

variable "lambda_create_game_stack_uri" {
  type = string
}

variable "lambda_create_game_stack_name" {
  type = string
}

variable "lambda_delete_game_stack_uri" {
  type = string
}

variable "lambda_delete_game_stack_name" {
  type = string
}

variable "lambda_start_game_server_uri" {
  type = string
}

variable "lambda_start_game_server_name" {
  type = string
}

variable "lambda_stop_game_server_uri" {
  type = string
}

variable "lambda_stop_game_server_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

# Cognito
variable "user_pool_client_id" {
  type = string
}

variable "cognito_user_pool_endpoint" {
  type = string
}

## CloudWatch
resource "aws_cloudwatch_log_group" "game_stacks_api_log_group" {
  name = "/aws/lambda/api"
}

## API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "api-${var.app_name}-${var.deployment_branch}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = (var.homepage_branch == "dev" ? ["https://${var.subdomain_homepage}.${var.hosted_zone_name}", "http://localhost:5173"] : ["https://${var.subdomain_homepage}.${var.hosted_zone_name}"])
    allow_methods = ["POST", "GET", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "Authorization"]
    max_age       = 300
  }
}

# Authorizer to manage which group can call which HTTP APIs
resource "aws_apigatewayv2_authorizer" "game_stacks_api_authorization" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [var.user_pool_client_id]
    issuer   = "https://${var.cognito_user_pool_endpoint}"
  }
}


resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id

  name        = "stage-${var.app_name}-${var.deployment_branch}"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.game_stacks_api_log_group.arn

    format = jsonencode({ "requestId" : "$context.requestId", "ip" : "$context.identity.sourceIp", "requestTime" : "$context.requestTime", "httpMethod" : "$context.httpMethod", "routeKey" : "$context.routeKey", "status" : "$context.status", "protocol" : "$context.protocol", "responseLength" : "$context.responseLength" }
    )
  }
}


# GET /gamestacks
resource "aws_apigatewayv2_integration" "integration_get_game_stacks" {
  api_id = aws_apigatewayv2_api.api.id

  integration_uri        = var.lambda_get_game_stacks_uri
  connection_type        = "INTERNET"
  payload_format_version = "2.0"
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
}

resource "aws_apigatewayv2_route" "route_get_game_stacks" {
  api_id = aws_apigatewayv2_api.api.id

  route_key = "GET /gamestacks"
  target    = "integrations/${aws_apigatewayv2_integration.integration_get_game_stacks.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.game_stacks_api_authorization.id
}

resource "aws_lambda_permission" "permission_get_game_stacks" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_get_game_stacks_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# POST /gamestack
resource "aws_apigatewayv2_integration" "integration_create_game_stack" {
  api_id = aws_apigatewayv2_api.api.id

  integration_uri        = var.lambda_create_game_stack_uri
  payload_format_version = "2.0"
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
}
resource "aws_apigatewayv2_route" "route_create_game_stack" {
  api_id = aws_apigatewayv2_api.api.id

  route_key          = "POST /gamestack"
  target             = "integrations/${aws_apigatewayv2_integration.integration_create_game_stack.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.game_stacks_api_authorization.id
}

resource "aws_lambda_permission" "permission_create_game_stack" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_create_game_stack_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}


# Delete /gamestack/{id}
resource "aws_apigatewayv2_integration" "integration_delete_game_stack" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.lambda_delete_game_stack_uri
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route_delete_game_stack" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "DELETE /gamestack/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.integration_delete_game_stack.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.game_stacks_api_authorization.id

}

resource "aws_lambda_permission" "permission_delete_game_stack" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_delete_game_stack_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}


# POST /startgameserver/{id}
resource "aws_apigatewayv2_integration" "integration_start_game_server" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.lambda_start_game_server_uri
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route_start_game_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /startgameserver/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.integration_start_game_server.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.game_stacks_api_authorization.id
}

resource "aws_lambda_permission" "permission_start_game_server" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_start_game_server_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# POST /stopgameserver/{id}
resource "aws_apigatewayv2_integration" "integration_stop_game_server" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.lambda_stop_game_server_uri
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route_stop_game_server" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /stopgameserver/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.integration_stop_game_server.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.game_stacks_api_authorization.id
}

resource "aws_lambda_permission" "permission_stop_game_server" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_stop_game_server_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}


# API Gateway domain name
resource "aws_acm_certificate" "api_domaine_name_certificate" {
  domain_name       = "${var.subdomain_api}.${var.hosted_zone_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "dns_record" {
  for_each = {
    for dvo in aws_acm_certificate.api_domaine_name_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "api_domaine_name_certificate_validation" {
  certificate_arn         = aws_acm_certificate.api_domaine_name_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_record : record.fqdn]
}

## Alias
resource "aws_apigatewayv2_domain_name" "api_gateway_domain" {
  depends_on  = [aws_acm_certificate_validation.api_domaine_name_certificate_validation]
  domain_name = aws_acm_certificate.api_domaine_name_certificate.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_domaine_name_certificate_validation.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}


resource "aws_route53_record" "api_domain_name_record" {
  name    = aws_apigatewayv2_domain_name.api_gateway_domain.domain_name
  type    = "A"
  zone_id = var.hosted_zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_apigatewayv2_domain_name.api_gateway_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_gateway_domain.domain_name_configuration[0].hosted_zone_id
  }
}

resource "aws_apigatewayv2_api_mapping" "mapping" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api_gateway_domain.id
  stage       = aws_apigatewayv2_stage.stage.id
}

output "api_https_url" {
  value = aws_route53_record.api_domain_name_record.name
}


