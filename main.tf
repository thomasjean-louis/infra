provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "terraform-tjl"
    key    = "terraform.tfstate"
    region = "eu-west-3"
  }
}

data "aws_caller_identity" "account_data" {}

data "aws_route53_zone" "project_route_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}


locals {
  account_id     = data.aws_caller_identity.account_data.account_id
  hosted_zone_id = data.aws_route53_zone.project_route_zone.zone_id
}


module "vpc" {
  source                      = "./vpc"
  az1                         = var.az1
  az2                         = var.az2
  vpc_cidr_block              = var.vpc_cidr_block
  public_subnet_a_cidr_block  = var.public_subnet_a_cidr_block
  private_subnet_a_cidr_block = var.private_subnet_a_cidr_block
  public_subnet_b_cidr_block  = var.public_subnet_b_cidr_block
  private_subnet_b_cidr_block = var.private_subnet_b_cidr_block
}

module "iam" {
  source   = "./iam"
  app_name = var.app_name
}

module "s3" {
  source   = "./s3"
  app_name = var.app_name
  region   = var.region
}

module "alb_gameserver" {
  source                     = "./gameserver/alb"
  app_name                   = var.app_name
  subdomain_game_stacks      = var.subdomain_game_stacks
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr_block             = var.vpc_cidr_block
  public_subnet_id_a         = module.vpc.public_subnet_id_a
  public_subnet_id_b         = module.vpc.public_subnet_id_b
  game_server_port           = var.game_server_port
  game_server_name_container = var.game_server_name_container
  hosted_zone_name           = var.hosted_zone_name
  hosted_zone_id             = local.hosted_zone_id
  proxy_server_port          = var.proxy_server_port

}

module "ecs" {
  source   = "./ecs"
  app_name = var.app_name
}


module "logs_game_server" {
  source         = "./logs"
  name_container = var.game_server_name_container
}

module "logs_proxy_server" {
  source         = "./logs"
  name_container = var.proxy_server_name_container
}


module "gameserver" {
  source                  = "./gameserver"
  cluster_id              = module.ecs.cluster_id
  app_name                = var.app_name
  vpc_id                  = module.vpc.vpc_id
  region                  = var.region
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn

  vpc_cidr_block      = var.vpc_cidr_block
  private_subnet_id_a = module.vpc.private_subnet_id_a
  private_subnet_id_b = module.vpc.private_subnet_id_b

  content_server_address = var.content_server_address

  proxy_server_cpu            = var.proxy_server_cpu
  proxy_server_ram            = var.proxy_server_ram
  proxy_server_port           = var.proxy_server_port
  proxy_server_image          = var.proxy_server_image
  proxy_server_name_container = var.proxy_server_name_container

  game_server_cpu            = var.game_server_cpu
  game_server_ram            = var.game_server_ram
  game_server_port           = var.game_server_port
  game_server_image          = var.game_server_image
  game_server_name_container = var.game_server_name_container

}

# Cloud Formation templates
module "cloud_formation" {
  depends_on     = [module.s3]
  source         = "./cloud_formation"
  region         = var.region
  s3-bucket-name = module.s3.s3-bucket-name
}

# Lambda functions
# module "lambda_gameserver" {
#   depends_on                          = [module.gameserver]
#   source                              = "./lambda_gameserver"
#   app_name                            = var.app_name
#   account_id                          = local.account_id
#   region                              = var.region
#   cluster_id                          = module.ecs.cluster_id
#   cluster_name                        = module.ecs.cluster_name
#   private_subnet_id_a                 = module.vpc.private_subnet_id_a
#   private_subnet_id_b                 = module.vpc.private_subnet_id_b
#   security_group_game_server_task     = module.gameserver.security_group_game_server_task
#   target_group_game_server_task_ws    = module.alb_gameserver.target_group_game_server_ws_arn
#   target_group_game_server_task_https = module.alb_gameserver.target_group_game_server_https_arn
#   task_definition_game_server         = module.gameserver.task_definition_game_server
#   role_task_execution_name            = module.iam.task_execution_role_name
#   proxy_server_name_container         = var.proxy_server_name_container
# }

# Serverless BackEnd
module "dynamodb" {
  source                     = "./dynamodb"
  gamestacks_table_name      = var.gamestacks_table_name
  game_stacks_id_column_name = var.game_stacks_id_column_name
}

module "lambda_game_stacks" {
  source                             = "./api_gateway_rest/lambda_game_stacks"
  region                             = var.region
  account_id                         = local.account_id
  app_name                           = var.app_name
  vpc_id                             = module.vpc.vpc_id
  gamestacks_table_name              = module.dynamodb.gamestacks_table_name
  create_game_stack_cf_stack_name    = var.create_game_stack_cf_stack_name
  create_game_stack_cf_template_url  = module.cloud_formation.create_game_stack_cf_template_url
  s3_bucket_cf_templates             = module.cloud_formation.s3_bucket_cf_templates
  hosted_zone_name                   = var.hosted_zone_name
  hosted_zone_id                     = local.hosted_zone_id
  public_subnet_id_a                 = module.vpc.public_subnet_id_a
  public_subnet_id_b                 = module.vpc.public_subnet_id_b
  security_group_alb_id              = module.alb_gameserver.security_group_alb_id
  proxy_server_port                  = var.proxy_server_port
  cluster_id                         = module.ecs.cluster_id
  security_group_game_server_task_id = module.gameserver.security_group_game_server_task
  private_subnet_id_a                = module.vpc.private_subnet_id_a
  private_subnet_id_b                = module.vpc.private_subnet_id_b
  task_definition_arn                = module.gameserver.task_definition_game_server_arn
  proxy_server_name_container        = var.proxy_server_name_container
  task_execution_role_name           = module.iam.task_execution_role_name

  game_stacks_id_column_name       = var.game_stacks_id_column_name
  game_stacks_capacity_column_name = var.game_stacks_capacity_column_name

  game_stacks_capacity_value                    = var.game_stacks_capacity_value
  game_stacks_server_link_column_name           = var.game_stacks_server_link_column_name
  game_stacks_cloud_formation_stack_name_column = var.game_stacks_cloud_formation_stack_name_column
  invoked_lambda_function_name                  = var.invoked_lambda_function_name
}


module "api_gateway_rest" {
  depends_on         = [module.dynamodb, module.lambda_game_stacks]
  source             = "./api_gateway_rest"
  region             = var.region
  account_id         = local.account_id
  app_name           = var.app_name
  subdomain_api      = var.subdomain_api
  hosted_zone_name   = var.hosted_zone_name
  hosted_zone_id     = local.hosted_zone_id
  subdomain_homepage = var.subdomain_homepage
  homepage_branch    = var.homepage_branch

  lambda_get_game_stacks_uri  = module.lambda_game_stacks.lambda_get_game_stacks_uri
  lambda_get_game_stacks_name = module.lambda_game_stacks.lambda_get_game_stacks_name

  lambda_create_game_stack_uri  = module.lambda_game_stacks.lambda_create_game_stack_uri
  lambda_create_game_stack_name = module.lambda_game_stacks.lambda_create_game_stack_name

}

# Cognito
module "cognito" {
  source                   = "./cognito"
  app_name                 = var.app_name
  default_cognito_username = var.default_cognito_username
  default_cognito_password = var.default_cognito_password
  hosted_zone_id           = local.hosted_zone_id
  subdomain_auth           = var.subdomain_auth
  hosted_zone_name         = var.hosted_zone_name
  default_cognito_mail     = var.default_cognito_mail
}

# Serverless FrontEnd
module "homepage" {
  depends_on              = [module.cognito]
  source                  = "./homepage"
  region                  = var.region
  amplify_app_name        = var.amplify_app_name
  homepage_repository     = var.homepage_repository
  homepage_branch         = var.homepage_branch
  subdomain_homepage      = var.subdomain_homepage
  hosted_zone_name        = var.hosted_zone_name
  homepage_github_token   = var.homepage_github_token
  load_balancer_https_url = module.alb_gameserver.load_balancer_https_url
  proxy_server_port       = var.proxy_server_port
  api_https_url           = module.api_gateway_rest.api_https_url
  user_pool_id            = module.cognito.user_pool_id
  user_pool_client_id     = module.cognito.user_pool_client_id
  identity_pool_id        = module.cognito.identity_pool_id
}




