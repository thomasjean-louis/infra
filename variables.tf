##### VPC
variable "region" {
  default = "eu-west-3"
}

variable "az1" {
  default = "eu-west-3a"
}

variable "az2" {
  default = "eu-west-3b"
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

variable "deployment_branch" {
  type      = string
  sensitive = true
}

###### R53
variable "hosted_zone_name" {
  type      = string
  sensitive = true
}

variable "subdomain_auth" {
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

###### Cognito
variable "default_cognito_username" {
  type      = string
  sensitive = true
}

variable "default_cognito_password" {
  type      = string
  sensitive = true
}

variable "default_cognito_mail" {
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
  default = 512
}

variable "proxy_server_ram" {
  default = 1024
}

variable "proxy_server_tag" {
  type = string
}

variable "uri_proxy_repo" {
  type      = string
  sensitive = true
}

## GameServer
variable "game_server_name_container" {
  type      = string
  sensitive = true
}

variable "game_server_cpu" {
  default = 512
}

variable "game_server_ram" {
  default = 1024
}

variable "game_server_port" {
  default = 27960
}

variable "game_server_tag" {
  type = string
}

variable "uri_game_server_repo" {
  type      = string
  sensitive = true
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

variable "game_stacks_id_column_name" {
  default = "ID"
}

variable "game_stacks_capacity_column_name" {
  default = "Capacity"
}

variable "game_stacks_capacity_value" {
  default = 4
}

variable "game_stacks_server_link_column_name" {
  default = "ServerLink"
}

variable "game_stacks_cloud_formation_stack_name_column" {
  default = "CloudFormationStackName"
}

variable "game_stacks_is_active_columnn_name" {
  default = "IsActive"
}

variable "service_name_column" {
  default = "ServiceName"  
}

variable "status_column_name" {
  default = "Status"
}

variable "running_value" {
  default = "running"
}

variable "stopped_value" {
  default = "stopped"
}

variable "pending_value" {
  default = "pending"
}

## Lambda
variable "create_game_stack_cf_stack_name" {
  default = "game-server-stack"
}

variable "invoked_lambda_function_name" {
  default = "add_game_stack"
}
