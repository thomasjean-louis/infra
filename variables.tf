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
variable "gameserver_name_container" {
  default= "gameserver"
}

variable "game_server_cpu" {
  default = 1024
}

variable "game_server_ram" {
  default = 2048
}

variable "game_server_port" {
  default = 80
}

variable "game_server_image" {
  default = "thomasjeanlouis1/gameserver:dev_12"
}

## WebServer - To update
variable "webs_server_name_container" {
  default= "gameserver"
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
  default = "thomasjeanlouis1/gameserver:dev_12"
}

