variable "app_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}


# IAM state machine roles and policies
resource "aws_iam_role" "step_function_waiter_role" {
  name = "${var.app_name}_step_function_waiter_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "state_machine_role_policy" {

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = "*"
  }
}


resource "aws_iam_role_policy" "invoke_lambda_policy" {
  name = "${var.app_name}_lambda_pass_role_task_definition_${var.deployment_branch}"
  role = aws_iam_role.step_function_waiter_role.id

  policy = data.aws_iam_policy_document.state_machine_role_policy.json
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/stepFunction/${var.app_name}_step_function_waiter_role"
}

resource "aws_iam_role_policy" "step_function_logs_policy" {
  name = "${var.app_name}_logs_policy_${var.deployment_branch}"
  role = aws_iam_role.step_function_waiter_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogDelivery",
          "logs:CreateLogStream",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "*"
      }
    ]
  })

}


# Step function
resource "aws_sfn_state_machine" "step_function_waiter" {
  name     = "${var.app_name}_step_function_waiter_role"
  role_arn = aws_iam_role.step_function_waiter_role.arn

  definition = templatefile("${path.module}/WaitStateMachine.asl.json")
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

output "wait_step_function_arn" {
  value = aws_sfn_state_machine.step_function_waiter.arn
}
