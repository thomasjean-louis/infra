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

}

# module "alb_web_server" {
#   source                    = "./webserver/alb"
#   app_name                  = var.app_name
#   vpc_id                    = module.vpc.vpc_id
#   vpc_cidr_block            = var.vpc_cidr_block
#   public_subnet_id_a        = module.vpc.public_subnet_id_a
#   public_subnet_id_b        = module.vpc.public_subnet_id_b
#   web_server_port           = var.web_server_port
#   web_server_name_container = var.web_server_name_container
# }

module "ecs" {
  source   = "./ecs"
  app_name = var.app_name
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

# module "webserver" {
#   source     = "./webserver"
#   depends_on = [module.gameserver]
#   app_name   = var.app_name
#   cluster_id = module.ecs.cluster_id

#   vpc_id                  = module.vpc.vpc_id
#   region                  = var.region
#   task_execution_role_arn = module.iam.task_execution_role_arn
#   task_role_arn           = module.iam.task_role_arn

#   vpc_cidr_block              = var.vpc_cidr_block
#   private_subnet_id_a         = module.vpc.private_subnet_id_a
#   private_subnet_id_b         = module.vpc.private_subnet_id_b
#   target_group_web_server_arn = module.alb_web_server.target_group_web_server_arn

#   content_server_address = var.content_server_address

#   web_server_cpu            = var.web_server_cpu
#   web_server_ram            = var.web_server_ram
#   web_server_port           = var.web_server_port
#   web_server_image          = var.web_server_image
#   web_server_name_container = var.web_server_name_container
#   gameserver_address        = module.alb_gameserver.alb_game_server_DNS
#   game_server_port          = var.game_server_port
# }


module "logs_game_server" {
  source         = "./logs"
  name_container = var.game_server_name_container
}


# module "logs_web_server" {
#   source         = "./logs"
#   name_container = var.web_server_name_container
# }

# Lambda functions
module "lambda_gameserver" {
  depends_on                      = [module.gameserver]
  source                          = "./lambda_gameserver"
  app_name                        = var.app_name
  account_id                      = data.aws_caller_identity.account_data.account_id
  region                          = var.region
  cluster_id                      = module.ecs.cluster_id
  cluster_name                    = module.ecs.cluster_name
  private_subnet_id_a             = module.vpc.private_subnet_id_a
  private_subnet_id_b             = module.vpc.private_subnet_id_b
  security_group_game_server_task = module.gameserver.security_group_game_server_task
  target_group_game_server_task   = module.alb_gameserver.target_group_game_server_arn
  task_definition_game_server     = module.gameserver.task_definition_game_server
  role_task_execution_name        = module.iam.task_execution_role_name
  proxy_server_name_container     = var.proxy_server_name_container

}

# Homepage
module "homepage" {
  source                = "./homepage"
  region                = var.region
  amplify_app_name      = var.amplify_app_name
  homepage_repository   = var.homepage_repository
  homepage_branch       = var.homepage_branch
  homepage_domain_name  = var.homepage_domain_name
  homepage_github_token = var.homepage_github_token

}
