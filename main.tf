provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "terraform-tjl"
    key    = "quakejs/terraform.tfstate"
    region = "eu-west-3"
  }
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
  source = "./iam"
}

module "alb" {
  source             = "./alb"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnet_id_a = module.vpc.public_subnet_id_a
  public_subnet_id_b = module.vpc.public_subnet_id_b
  game_server_port   = var.game_server_port

}

module "ecs" {
  source                       = "./ecs"
  vpc_id                       = module.vpc.vpc_id
  region                       = var.region
  task_execution_role_arn      = module.iam.task_execution_role_arn
  task_role_arn                = module.iam.task_role_arn
  game_server_cpu              = var.game_server_cpu
  game_server_ram              = var.game_server_ram
  game_server_port             = var.game_server_port
  game_server_image            = var.game_server_image
  vpc_cidr_block               = var.vpc_cidr_block
  private_subnet_id_a          = module.vpc.private_subnet_id_a
  private_subnet_id_b          = module.vpc.private_subnet_id_b
  target_group_game_server_arn = module.alb.target_group_game_server_arn
  gameserver_name_container    = var.gameserver_name_container
}


