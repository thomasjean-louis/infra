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



###### ECS

## Global
variable "content_server_address" {
  default = "d18ztv6taz5um2.cloudfront.net"
}

## GameServer
variable "game_server_name_container" {
  default = "gameserver"
}

variable "game_server_cpu" {
  default = 1024
}

variable "game_server_ram" {
  default = 2048
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
  default = 80
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

variable "homepage_domain_name" {
  type      = string
  sensitive = true
}


variable "homepage_github_token" {
  type      = string
  sensitive = true
}
