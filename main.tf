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

locals {
  account_id = data.aws_caller_identity.account_data.account_id
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
  author   = var.author
}

module "alb_gameserver" {
  source                     = "./gameserver/alb"
  app_name                   = var.app_name
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr_block             = var.vpc_cidr_block
  public_subnet_id_a         = module.vpc.public_subnet_id_a
  public_subnet_id_b         = module.vpc.public_subnet_id_b
  game_server_port           = var.game_server_port
  game_server_name_container = var.game_server_name_container
  hosted_zone_name           = var.hosted_zone_name
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


# Lambda functions
module "lambda_gameserver" {
  depends_on                          = [module.gameserver]
  source                              = "./lambda_gameserver"
  app_name                            = var.app_name
  account_id                          = local.account_id
  region                              = var.region
  cluster_id                          = module.ecs.cluster_id
  cluster_name                        = module.ecs.cluster_name
  private_subnet_id_a                 = module.vpc.private_subnet_id_a
  private_subnet_id_b                 = module.vpc.private_subnet_id_b
  security_group_game_server_task     = module.gameserver.security_group_game_server_task
  target_group_game_server_task_ws    = module.alb_gameserver.target_group_game_server_ws_arn
  target_group_game_server_task_https = module.alb_gameserver.target_group_game_server_https_arn
  task_definition_game_server         = module.gameserver.task_definition_game_server
  role_task_execution_name            = module.iam.task_execution_role_name
  proxy_server_name_container         = var.proxy_server_name_container
}

# Homepage
module "homepage" {
  source                  = "./homepage"
  region                  = var.region
  amplify_app_name        = var.amplify_app_name
  homepage_repository     = var.homepage_repository
  homepage_branch         = var.homepage_branch
  homepage_domain_name    = var.homepage_domain_name
  homepage_github_token   = var.homepage_github_token
  load_balancer_https_url = module.alb_gameserver.load_balancer_https_url
  proxy_server_port       = var.proxy_server_port
}

module "cloud_formation" {
  depends_on     = [module.s3]
  source         = "./cloud_formation"
  s3-bucket-name = module.s3.s3-bucket-name
}

# module "cloud_formation" {
#   depends_on                         = [module.alb_gameserver]
#   source                             = "./cloud_formation"
#   vpc_id                             = module.vpc.vpc_id
#   hosted_zone_name                   = var.hosted_zone_name
#   public_subnet_id_a                 = module.vpc.public_subnet_id_a
#   public_subnet_id_b                 = module.vpc.public_subnet_id_b
#   security_group_alb_id              = module.alb_gameserver.security_group_alb_id
#   proxy_server_port                  = var.proxy_server_port
#   private_subnet_id_a                = module.vpc.private_subnet_id_a
#   private_subnet_id_b                = module.vpc.private_subnet_id_b
#   task_definition_arn                = module.gameserver.task_definition_game_server_arn
#   proxy_server_name_container        = var.proxy_server_name_container
#   cluster_id                         = module.ecs.cluster_id
#   security_group_game_server_task_id = module.gameserver.security_group_game_server_task
# }

module "dynamodb" {
  source                = "./dynamodb"
  gamestacks_table_name = var.gamestacks_table_name
  gamestack_id          = var.gamestack_id
}

module "lambda_game_stacks" {
  source                = "./api_gateway_rest/lambda_game_stacks"
  app_name              = var.app_name
  gamestacks_table_name = module.dynamodb.gamestacks_table_name
}

module "api_gateway_rest" {
  depends_on                  = [module.dynamodb, module.lambda_game_stacks]
  source                      = "./api_gateway_rest"
  region                      = var.region
  account_id                  = local.account_id
  app_name                    = var.app_name
  homepage_https_url          = module.alb_gameserver.load_balancer_https_url
  lambda_get_game_stacks_uri  = module.lambda_game_stacks.lambda_get_game_stacks_uri
  lambda_get_game_stacks_name = module.lambda_game_stacks.lambda_get_game_stacks_name
}

output "base_url" {
  value = module.api_gateway_rest.base_url
}
