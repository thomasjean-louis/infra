variable "region" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "game_server_cpu" {
  type = number
}

variable "game_server_ram" {
  type = number
}

variable "game_server_port" {
  type = number
}

variable "game_server_image" {
  type = string
}

resource "aws_ecs_cluster" "main" {
    name = "quakejs-cluster"
}

data "template_file" "game_server_template "{
    template = file("./taskdefinition.json.tpl")
    vars = {
      name = "gameserver"
      port = var.game_server_port
      cpu = var.game_server_cpu
      ram = var.game_server_ram
      region = var.region
      image = var.game_server_image
    }
}

resource "aws_ecs_task_definition" "game_server" {
    family                   = "quakejs"
    execution_role_arn       = var.task_execution_role_arn
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = var.game_server_cpu
    memory                   = var.game_server_ram
    container_definitions = data.template_file
}