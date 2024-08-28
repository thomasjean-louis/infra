## Project config 
provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

## Global variables
data "aws_caller_identity" "account_data" {}

data "aws_route53_zone" "project_route_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}


locals {
  account_id     = data.aws_caller_identity.account_data.account_id
  hosted_zone_id = data.aws_route53_zone.project_route_zone.zone_id
}

## Modules
module "vpc" {
  source                      = "./vpc"
  region                      = var.region
  az1                         = var.az1
  az2                         = var.az2
  vpc_cidr_block              = var.vpc_cidr_block
  public_subnet_a_cidr_block  = var.public_subnet_a_cidr_block
  private_subnet_a_cidr_block = var.private_subnet_a_cidr_block
  public_subnet_b_cidr_block  = var.public_subnet_b_cidr_block
  private_subnet_b_cidr_block = var.private_subnet_b_cidr_block
  deployment_branch           = var.deployment_branch
}

module "iam" {
  source            = "./iam"
  app_name          = var.app_name
  deployment_branch = var.deployment_branch
}

module "bucket" {
  source            = "./bucket"
  app_name          = var.app_name
  region            = var.region
  deployment_branch = var.deployment_branch
}

module "waf" {

  source   = "./waf"
  app_name = var.app_name
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
  proxy_server_port          = var.proxy_server_port
  deployment_branch          = var.deployment_branch

}

module "ecs" {
  source            = "./ecs"
  app_name          = var.app_name
  deployment_branch = var.deployment_branch
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
  proxy_server_tag            = var.proxy_server_tag
  uri_proxy_repo              = var.uri_proxy_repo
  proxy_server_name_container = var.proxy_server_name_container

  game_server_cpu            = var.game_server_cpu
  game_server_ram            = var.game_server_ram
  game_server_port           = var.game_server_port
  game_server_tag            = var.game_server_tag
  game_server_name_container = var.game_server_name_container
  uri_game_server_repo       = var.uri_game_server_repo

  deployment_branch = var.deployment_branch
}

# Cloud Formation templates
module "cloud_formation" {
  depends_on     = [module.bucket]
  source         = "./cloud_formation"
  region         = var.region
  s3-bucket-name = module.bucket.s3-bucket-name
}

# Serverless BackEnd
module "dynamodb" {
  source                     = "./dynamodb"
  gamestacks_table_name      = var.gamestacks_table_name
  game_stacks_id_column_name = var.game_stacks_id_column_name
  deployment_branch          = var.deployment_branch
}

# Step function
module "step_function" {
  source                           = "./step_function"
  region                           = var.region
  account_id                       = local.account_id
  app_name                         = var.app_name
  deployment_branch                = var.deployment_branch
  nb_seconds_before_server_stopped = var.nb_seconds_before_server_stopped
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
  pending_value                      = var.pending_value
  stopped_value                      = var.stopped_value
  running_value                      = var.running_value
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
  cluster_name                       = module.ecs.cluster_name


  game_stacks_id_column_name       = var.game_stacks_id_column_name
  game_stacks_capacity_column_name = var.game_stacks_capacity_column_name

  game_stacks_capacity_value                    = var.game_stacks_capacity_value
  game_stacks_server_link_column_name           = var.game_stacks_server_link_column_name
  game_stacks_cloud_formation_stack_name_column = var.game_stacks_cloud_formation_stack_name_column
  invoked_lambda_function_name                  = var.invoked_lambda_function_name
  game_stacks_is_active_columnn_name            = var.game_stacks_is_active_columnn_name
  service_name_column                           = var.service_name_column
  status_column_name                            = var.status_column_name
  stop_server_time_column_name                  = var.stop_server_time_column_name

  deployment_branch = var.deployment_branch
  waf_arn           = module.waf.waf_web_acl_arn

  wait_step_function_arn           = module.step_function.wait_step_function_arn
  nb_seconds_before_server_stopped = var.nb_seconds_before_server_stopped
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

  lambda_delete_game_stack_uri  = module.lambda_game_stacks.lambda_delete_game_stack_uri
  lambda_delete_game_stack_name = module.lambda_game_stacks.lambda_delete_game_stack_name

  lambda_start_game_server_uri  = module.lambda_game_stacks.lambda_start_game_server_uri
  lambda_start_game_server_name = module.lambda_game_stacks.lambda_start_game_server_name

  lambda_stop_game_server_uri  = module.lambda_game_stacks.lambda_stop_game_server_uri
  lambda_stop_game_server_name = module.lambda_game_stacks.lambda_stop_game_server_name

  deployment_branch = var.deployment_branch
}

# Cognito
module "cognito" {
  source                   = "./cognito"
  app_name                 = var.app_name
  admin_cognito_username   = var.admin_cognito_username
  admin_cognito_password   = var.admin_cognito_password
  classic_cognito_username = var.classic_cognito_username
  classic_cognito_password = var.classic_cognito_password

  hosted_zone_id       = local.hosted_zone_id
  subdomain_auth       = var.subdomain_auth
  hosted_zone_name     = var.hosted_zone_name
  default_cognito_mail = var.default_cognito_mail
  deployment_branch    = var.deployment_branch
  admin_group_name     = var.admin_group_name
  user_group_name      = var.user_group_name
}

# Serverless FrontEnd
module "homepage" {
  depends_on            = [module.cognito]
  source                = "./homepage"
  region                = var.region
  amplify_app_name      = var.amplify_app_name
  homepage_repository   = var.homepage_repository
  homepage_branch       = var.homepage_branch
  subdomain_homepage    = var.subdomain_homepage
  hosted_zone_name      = var.hosted_zone_name
  homepage_github_token = var.homepage_github_token
  proxy_server_port     = var.proxy_server_port
  api_https_url         = module.api_gateway_rest.api_https_url
  user_pool_id          = module.cognito.user_pool_id
  user_pool_client_id   = module.cognito.user_pool_client_id
  identity_pool_id      = module.cognito.identity_pool_id
  deployment_branch     = var.deployment_branch
}






