
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


resource "aws_amplify_app" "homepage_app" {
  name        = var.amplify_app_name
  oauth_token = var.homepage_github_token
  repository  = var.homepage_repository

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
