##### VPC
variable "region" {
  default = "us-east-1"
}

variable "az1" {
  default = "us-east-1a"
}

variable "az2" {
  default = "us-east-1b"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet_a_cidr_block" {
  default = "10.0.1.0/24"
}

variable "private_subnet_a_cidr_block" {
  default = "10.0.2.0/24"
}

variable "public_subnet_b_cidr_block" {
  default = "10.0.3.0/24"
}

variable "private_subnet_b_cidr_block" {
  default = "10.0.4.0/24"
}

###### Project
variable "app_name" {
  type      = string
  sensitive = true
}

###### R53
variable "hosted_zone_name" {
  type      = string
  sensitive = true
}

variable "subdomain_homepage" {
  type      = string
  sensitive = true
}

variable "subdomain_game_stacks" {
  type      = string
  sensitive = true
}

variable "subdomain_api" {
  type      = string
  sensitive = true
}


###### ECS

## Global
variable "content_server_address" {
  type      = string
  sensitive = true
}

## Proxy
variable "proxy_server_name_container" {
  type      = string
  sensitive = true
}


variable "proxy_server_port" {
  default = 27961
}

variable "proxy_server_cpu" {
  default = 1024
}

variable "proxy_server_ram" {
  default = 2048
}

variable "proxy_server_image" {
  default = ""
}

## GameServer
variable "game_server_name_container" {
  type      = string
  sensitive = true
}

variable "game_server_cpu" {
  default = 2048
}

variable "game_server_ram" {
  default = 4096
}

variable "game_server_port" {
  default = 27960
}

variable "game_server_image" {
  default = ""
}

## WebServer 
variable "web_server_name_container" {
  default = "webserver"
}

variable "web_server_cpu" {
  default = 1024
}

variable "web_server_ram" {
  default = 2048
}

variable "web_server_port" {
  default = 443
}

variable "web_server_image" {
  default = ""

}

## Homepage
variable "amplify_app_name" {
  default = "homepage"
}

variable "homepage_repository" {
  type      = string
  sensitive = true
}

variable "homepage_branch" {
  default = "default_branch"
}

variable "homepage_github_token" {
  type      = string
  sensitive = true
}

## DynamoDB
variable "gamestacks_table_name" {
  default = "gamestacks"
}

variable "gamestack_id" {
  default = "ID"
}

## Lambda
variable "create_game_stack_cf_stack_name" {
  default = "game-server-stack"
}
