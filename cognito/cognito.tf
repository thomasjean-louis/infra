variable "app_name" {
  type = string
}

variable "default_cognito_username" {
  type = string
}

variable "default_cognito_password" {
  type = string
}

resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.app_name}-user-pool"

  password_policy {
    minimum_length                   = 6
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                         = "${var.app_name}-user-pool_client"
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${var.app_name}-identity-pool"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.user_pool_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_user" "default_cognito_user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.default_cognito_username
  password     = var.default_cognito_password

  enabled = true

  attributes = {
    email          = "default@mail.com"
    email_verified = true
  }
}
