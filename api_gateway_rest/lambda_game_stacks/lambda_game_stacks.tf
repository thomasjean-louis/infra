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

variable "create_game_stack_cf_stack_name" {
  type = string
}

variable "create_game_stack_cf_template_url" {
  type = string
}

variable "s3_bucket_cf_templates" {
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

resource "aws_iam_role_policy" "cloud_formation_service_policy" {
  name = "${var.app_name}_lambda_cloud_formation_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudformation:CreateStack"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:cloudformation:${var.region}:${var.account_id}:stack/${var.create_game_stack_cf_stack_name}*/*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "s3_service_policy" {
  name = "${var.app_name}_lambda_s3_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_cf_templates}/*"
      },
    ]
  })
}

# GET /gamestacks
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

# POST /gamestack
data "archive_file" "create_game_stack_zip" {
  type        = "zip"
  source_file = "${path.module}/create_game_stack.py"
  output_path = "${path.module}/create_game_stack.zip"
}

resource "aws_lambda_function" "lambda_create_game_stack" {
  function_name    = "create_game_stack"
  filename         = data.archive_file.create_game_stack_zip.output_path
  source_code_hash = data.archive_file.create_game_stack_zip.output_base64sha256
  role             = aws_iam_role.lambda_api_service_role.arn
  handler          = "create_game_stack.lambda_handler"
  runtime          = "python3.9"
  timeout          = 20

  environment {
    variables = {
      CREATE_GAME_SERVER_CF_STACK_NAME   = var.create_game_stack_cf_stack_name
      CREATE_GAME_SERVER_CF_TEMPLATE_URL = var.create_game_stack_cf_template_url
    }
  }
}

output "lambda_create_game_stack_uri" {
  value = aws_lambda_function.lambda_create_game_stack.invoke_arn
}

output "lambda_create_game_stack_name" {
  value = aws_lambda_function.lambda_create_game_stack.function_name
}


