variable "cluster_id" {
  type = string
}

variable "private_subnet_id_a" {
  type = string
}

variable "private_subnet_id_b" {
  type = string
}

variable "security_group_game_server_task" {
  type = string
}

variable "target_group_game_server_task" {
  type = string
}

variable "task_definition_game_server" {
  type = string
}


data "archive_file" "zip" {
  type        = "zip"
  source_file = "create_game_server_ecs_service.py"
  output_path = "create_game_server_ecs_service.zip"
}

# iam Lambda role
resource "aws_iam_role" "lambda_game_server_service_role" {
  name = "quakejs_lambda_game_server_service_role"

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

# Lambda creating GameServer ECS Service function
resource "aws_lambda_function" "lambda_game_server" {
  function_name    = "create_game_server_ecs_service"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = aws_iam_role.lambda_game_server_service_role.arn
  handler          = "create_game_server_ecs_service.lambda_handler"
  runtime          = "python3.6"

  environment {
    variables = {
      GAME_SERVER_SERVICE_CLUSTER_ID       = var.cluster_id,
      GAME_SERVER_SERVICE_SUBNET_ID_A      = var.private_subnet_id_a,
      GAME_SERVER_SERVICE_SUBNET_ID_B      = var.private_subnet_id_b,
      GAME_SERVER_SERVICE_SECURITY_GROUP   = var.security_group_game_server_task,
      GAME_SERVER_SERVICE_TARGET_GROUP_ARN = var.target_group_game_server_task,
      GAME_SERVER_SERVICE_TASK_DEFINITION  = var.task_definition_game_server,
    }
  }
}
