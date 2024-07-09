provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-tjl"
    key    = "quakejs/terraform.tfstate"
    region = "eu-west-3"
  }
}


module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}

module "alb" {
  source             = "./alb"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  public_subnet_id_a = module.vpc.public_subnet_id_a
  public_subnet_id_b = module.vpc.public_subnet_id_b

}
