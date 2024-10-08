variable "app_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.app_name}_task_execution_role"

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
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Get AWS Managed Policy for ecr 
data "aws_iam_policy" "ecr_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = data.aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy" "logs_policy" {
  name = "${var.app_name}_logs_policy_${var.deployment_branch}"
  role = aws_iam_role.task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

}

resource "aws_iam_role" "task_role" {
  name = "${var.app_name}_task_role_${var.deployment_branch}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

}

output "task_execution_role_arn" {
  value = aws_iam_role.task_execution_role.arn
}

output "task_execution_role_name" {
  value = aws_iam_role.task_execution_role.name
}

output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}

