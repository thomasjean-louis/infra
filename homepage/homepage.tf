

variable "region" {
  type = string
}

variable "hosted_zone_name" {
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

variable "subdomain_homepage" {
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

variable "api_https_url" {
  type = string
}

variable "user_pool_id" {
  type = string
}

variable "user_pool_client_id" {
  type = string
}

variable "identity_pool_id" {
  type = string
}

variable "deployment_branch" {
  type = string
}

# iam Amplify role
resource "aws_iam_role" "amplify_service_role" {
  name = "amplify_service_role_${var.deployment_branch}"

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
  name        = var.amplify_app_name + "_${var.deployment_branch}"
  oauth_token = var.homepage_github_token
  repository  = var.homepage_repository

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
            - echo "VITE_API_HTTPS_URL=${var.api_https_url}" >> .env
            - echo "VITE_USER_POOL_ID=${var.user_pool_id}" >> .env
            - echo "VITE_USER_POOL_CLIENT_ID=${var.user_pool_client_id}" >> .env
            - echo "VITE_IDENTITY_POOL_ID=${var.identity_pool_id}" >> .env
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

# Amplify will create ACM certificate + Cname record for us

resource "aws_amplify_domain_association" "domain_association" {
  app_id                = aws_amplify_app.homepage_app.id
  domain_name           = "${var.subdomain_homepage}.${var.hosted_zone_name}"
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.homepage_branch.branch_name
    prefix      = var.homepage_branch
  }
}
