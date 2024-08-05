variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "vpc_id" {
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

# Var POST /gamestack

variable "hosted_zone_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "public_subnet_id_a" {
  type = string
}

variable "public_subnet_id_b" {
  type = string
}

variable "security_group_alb_id" {
  type = string
}

variable "proxy_server_port" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "security_group_game_server_task_id" {
  type = string
}

variable "private_subnet_id_a" {
  type = string
}

variable "private_subnet_id_b" {
  type = string
}

variable "task_definition_arn" {
  type = string
}

variable "proxy_server_name_container" {
  type = string
}

variable "task_execution_role_name" {
  type = string
}

# Var Put /gamestack
variable "game_stacks_id_column_name" {
  type = string
}

variable "game_stacks_capacity_column_name" {
  type = string
}

variable "game_stacks_capacity_value" {
  type = number
}

variable "game_stacks_server_link_column_name" {
  type = string
}

variable "invoked_lambda_function_name" {
  type = string
}


## Lambda scripts

## IAM Lambda role

# Lambda Invoker role
resource "aws_iam_role" "lambda_invoker_role" {
  name = "${var.app_name}_lambda_invoker_role"

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

# API IAM role
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

resource "aws_iam_role_policy" "acm_service_policy" {
  name = "${var.app_name}_lambda_acm_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "acm:RequestCertificate",
          "acm:AddTagsToCertificate"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:acm:${var.region}:${var.account_id}:certificate/*"
      },
      {
        Action = [
          "acm:DescribeCertificate",
          "acm:DeleteCertificate"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]

  })
}

resource "aws_iam_role_policy" "alb_service_policy" {
  name = "${var.app_name}_lambda_alb_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticloadbalancing:DeleteListener",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:listener/*"
        }, {
        Action = [
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:CreateListener",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:loadbalancer/*"
        }, {
        Action = [
          "elasticloadbalancing:CreateTargetGroup",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:targetgroup/*"
        }, {
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeListeners"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "route_53_service_policy" {
  name = "${var.app_name}_lambda_route_53_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Action = [
          "route53:GetChange"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::change/*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecs_service_policy" {
  name = "${var.app_name}_lambda_ecs_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:CreateService"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ecs:${var.region}:${var.account_id}:service/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_service_policy" {
  name = "${var.app_name}_lambda_iam_service"
  role = aws_iam_role.lambda_api_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${var.account_id}:role/${var.task_execution_role_name}"
      }
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
      VPC_ID                             = var.vpc_id
      HOSTED_ZONE_NAME                   = var.hosted_zone_name
      HOSTED_ZONE_ID                     = var.hosted_zone_id
      PUBLIC_SUBNET_IA_A                 = var.public_subnet_id_a
      PUBLIC_SUBNET_IA_B                 = var.public_subnet_id_b
      SECURITY_GROUP_ALB_ID              = var.security_group_alb_id
      PROXY_SERVER_PORT                  = var.proxy_server_port
      CLUSTER_ID                         = var.cluster_id
      SECURITY_GROUP_GAME_SERVER_TASK_ID = var.security_group_game_server_task_id
      PRIVATE_SUBNET_A                   = var.private_subnet_id_a
      PRIVATE_SUBNET_B                   = var.private_subnet_id_b
      TASK_DEFINITION_ARN                = var.task_definition_arn
      PROXY_SERVER_NAME_CONTAINER        = var.proxy_server_name_container
      LAMBDA_INVOKER_ROLE_ARN            = aws_iam_role.lambda_invoker_role.arn
      INVOKED_LAMBDA_FUNCTION_NAME       = var.invoked_lambda_function_name
    }
  }
}

# PUT /gamestack
data "archive_file" "add_game_stack_zip" {
  type        = "zip"
  source_file = "${path.module}/add_game_stack.py"
  output_path = "${path.module}/add_game_stack.zip"
}

resource "aws_lambda_function" "lambda_add_game_stack" {
  function_name    = var.invoked_lambda_function_name
  filename         = data.archive_file.create_game_stack_zip.output_path
  source_code_hash = data.archive_file.create_game_stack_zip.output_base64sha256
  role             = aws_iam_role.lambda_api_service_role.arn
  handler          = "add_game_stack.lambda_handler"
  runtime          = "python3.9"
  timeout          = 20

  environment {
    variables = {
      GAME_STACKS_ID_COLUMN_NAME          = var.game_stacks_id_column_name
      GAME_STACKS_CAPACITY_COLUMN_NAME    = var.game_stacks_capacity_column_name
      GAME_STACKS_CAPACITY_VALUE          = var.game_stacks_capacity_column_name
      GAME_STACKS_SERVER_LINK_COLUMN_NAME = var.game_stacks_server_link_column_name
    }
  }
}

output "lambda_create_game_stack_uri" {
  value = aws_lambda_function.lambda_create_game_stack.invoke_arn
}

output "lambda_create_game_stack_name" {
  value = aws_lambda_function.lambda_create_game_stack.function_name
}


