variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "gamestacks_table_name" {
  type = string
}


## Lambda scripts

# IAM Lambda role

resource "aws_iam_role" "lambda_api_service_role" {
  name = "${var.app_name}_lambda_gateway_api_service_role"

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

resource "aws_iam_role_policy" "dynamodb_service_policy" {
  name = "${var.app_name}_lambda_dynamodb_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.gamestacks_table_name}"
      },
    ]
  })
}

# GET API

data "archive_file" "get_game_stacks_zip" {
  type        = "zip"
  source_file = "${path.module}/get_game_stacks.py"
  output_path = "${path.module}/get_game_stacks.zip"
}

resource "aws_lambda_function" "lambda_get_game_stacks" {
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

output "lambda_get_game_stacks_uri" {
  value = aws_lambda_function.lambda_get_game_stacks.invoke_arn
}

output "lambda_get_game_stacks_name" {
  value = aws_lambda_function.lambda_get_game_stacks.function_name
}

