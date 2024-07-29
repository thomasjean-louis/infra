variable "app_name" {
  type = string
}

variable "gamestacks_table_name" {
  type = string
}


resource "aws_api_gateway_rest_api" "api_gateway_gamestacks" {

  name = "api-${var.app_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

}


resource "aws_api_gateway_resource" "root" {

  rest_api_id = aws_api_gateway_rest_api.api_gateway_gamestacks.id
  parent_id   = aws_api_gateway_rest_api.api_gateway_gamestacks.root_resource_id
  path_part   = "mypath"

}

## Lambda scripts

# IAM Lambda role

resource "aws_iam_role" "lambda_api_service_role" {
  name = "${var.app_name}_lambda_api_service_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# resource "aws_iam_role_policy" "dynamodb_service_policy" {
#   name = "${var.app_name}_lambda_dynamodb_service"
#   role = aws_iam_role.lambda_game_server_service_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "ecs:CreateService"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:ecs:${var.region}:${var.account_id}:service/${var.cluster_name}/*"
#       },
#     ]
#   })
# }

# GET API

data "archive_file" "get_game_stacks_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_scripts/get_game_stacks.py"
  output_path = "${path.module}/lambda_scripts/get_game_stacks.zip"
}

resource "aws_lambda_function" "lambda_game_server" {
  function_name    = "get_game_stacks"
  filename         = data.archive_file.get_game_stacks_zip.output_path
  source_code_hash = data.archive_file.get_game_stacks_zip.output_base64sha256
  role             = aws_iam_role.lambda_api_service_role.arn
  handler          = "get_game_stacks.lambda_handler"
  runtime          = "python3.9"
  timeout          = 20

  environment {
    variables = {
      GAME_STACKS_TABLE_NAME = var.gamestacks_table_name
    }
  }
}

