provider "aws" {
  region     = "us-east-1"
  #access_key = "TF_VAR_ACCESS_KEY_INFRA"
  #secret_key = "TF_VAR_SECRET_ACCESS_KEY_INFRA"
  access_key = "AKIA5FTZENNJHATMDM3W"
  secret_key = "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"

}

terraform {
  backend "s3" {
    bucket     = "terraform-tjl"
    key        = "quakejs/terraform.tfstate"
    region     = "eu-west-3"
    access_key = "TF_VAR_ACCESS_KEY_STATE"
    secret_key = "TF_VAR_SECRET_ACCESS_KEY_STATE"

  }
}


module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}
