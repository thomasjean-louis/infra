variable "app_name" {
  type = string
}

variable "nb_seconds_before_server_stopped" {
  type = number
}

variable "lambda_stop_server_arn" {
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

    resources = [var.lambda_stop_server_arn]
  }
}


resource "aws_iam_role_policy" "invoke_lambda_policy" {
  name = "${var.app_name}_lambda_pass_role_task_definition"
  role = aws_iam_role.step_function_waiter_role.id

  policy = data.aws_iam_policy_document.state_machine_role_policy.json
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/stepFunction/${var.app_name}_step_function_waiter_role"
}



# Step function
resource "aws_sfn_state_machine" "step_function_waiter" {
  name     = "${var.app_name}_step_function_waiter_role"
  role_arn = aws_iam_role.step_function_waiter_role.arn

  definition = templatefile("${path.module}/WaitStateMachine.asl.json", {
    SecondsToWait         = var.nb_seconds_before_server_stopped,
    ArnStopServerFunction = var.lambda_stop_server_arn
    }
  )
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

