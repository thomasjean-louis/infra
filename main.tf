provider "aws" {
  region     = "us-east-1"
}

terraform {
  backend "s3" {
    bucket     = "terraform-tjl"
    key        = "quakejs/terraform.tfstate"
    region     = "eu-west-3"
  }
}


module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}
