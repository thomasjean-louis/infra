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
variable "task_execution_role_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "game_server_cpu" {
  default = 1
}

variable "game_server_ram" {
  type = 1
}

variable "game_server_port" {
  type = 27960
}

variable "game_server_image" {
  type = "thomasjeanlouis1/gameserver"
}
