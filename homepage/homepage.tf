

variable "region" {
  type = string
}

variable "amplify_app_name" {
  type = string
}

variable "homepage_repository" {
  type = string
}

variable "homepage_branch" {
  type = string
}

variable "homepage_domain_name" {
  type = string
}

variable "homepage_github_token" {
  type = string
}

# iam Amplify role
resource "aws_iam_role" "amplify_service_role" {
  name = "amplify_service_role"

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
          Service = ["amplify.amazonaws.com", "amplify.${var.region}.amazonaws.com"]
        }
      },
    ]
  })

}


resource "aws_amplify_app" "homepage_app" {
  name                     = var.amplify_app_name
  oauth_token              = var.homepage_github_token
  repository               = var.homepage_repository
  enable_branch_auto_build = true
  iam_service_role_arn     = aws_iam_role.amplify_service_role.arn
  build_spec               = <<-EOT
    version: 0.1
    frontend:
      phases:
        preBuild:
          commands:
            - yarn install
        build:
          commands:
            - yarn run build
      artifacts:
        baseDirectory: /
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

}

resource "aws_amplify_branch" "homepage_branch" {
  app_id      = aws_amplify_app.homepage_app.id
  branch_name = var.homepage_branch

}

resource "aws_amplify_domain_association" "domain_association" {
  app_id                = aws_amplify_app.homepage_app.id
  domain_name           = var.homepage_domain_name
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.homepage_branch.branch_name
    prefix      = var.homepage_branch
  }

}
