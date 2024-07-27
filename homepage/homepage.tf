

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

variable "load_balancer_https_url" {
  type = string
}

variable "proxy_server_port" {
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

data "aws_iam_policy" "administratorAccessamplify" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

resource "aws_iam_role_policy_attachment" "AdministratorAccess-Amplify-attach" {
  role       = aws_iam_role.amplify_service_role.name
  policy_arn = data.aws_iam_policy.administratorAccessamplify.arn
}



resource "aws_amplify_app" "homepage_app" {
  name        = var.amplify_app_name
  oauth_token = var.homepage_github_token
  repository  = var.homepage_repository

  # enable_auto_branch_creation = true

  # auto_branch_creation_patterns = ["main", "dev"]

  # auto_branch_creation_config {
  #   # Enable auto build for the created branch.
  #   enable_auto_build = true
  # }

  iam_service_role_arn = aws_iam_role.amplify_service_role.arn
  build_spec           = <<-EOT
    version: 0.1
    frontend:
      phases:
        preBuild:
          commands:
            - yarn install
        build:
          commands:
            - echo "VITE_LOAD_BALANCER_HTTPS_URL=${var.load_balancer_https_url}:${var.proxy_server_port}" >> .env
            - cat .env # This is optional, just to verify the contents of .env
            - yarn run build
      artifacts:
        baseDirectory: build
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
  app_id            = aws_amplify_app.homepage_app.id
  branch_name       = var.homepage_branch
  enable_auto_build = true

  stage = "PRODUCTION"

}

resource "aws_amplify_webhook" "build_branch" {
  depends_on = [aws_amplify_branch.homepage_branch]

  app_id      = aws_amplify_app.homepage_app.id
  branch_name = var.homepage_branch
  description = "trigger-amplify-build"
}

# output "amplify-webhook-url" {
#   value = aws_amplify_webhook.build_branch.url
# }

# Build Amplify website
resource "null_resource" "amplify-webhook-url" {
  depends_on = [aws_amplify_webhook.build_branch]
  provisioner "local-exec" {
    command = <<EOT
        curl -X POST \
             -H "Content-Type:application/json" \
             -d {} "${aws_amplify_webhook.build_branch.url}"
EOT
  }
}


# resource "aws_amplify_domain_association" "domain_association" {
#   app_id                = aws_amplify_app.homepage_app.id
#   domain_name           = var.homepage_domain_name
#   wait_for_verification = false

#   sub_domain {
#     branch_name = aws_amplify_branch.homepage_branch.branch_name
#     prefix      = var.homepage_branch
#   }

# }
