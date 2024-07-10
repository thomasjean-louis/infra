variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
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

variable "private_subnet_id_a" {
  type = string
}

variable "private_subnet_id_b" {
  type = string
}

variable "target_group_game_server_arn" {
  type = string
}

variable "gameserver_name_container" {
  type = string
}

resource "aws_ecs_cluster" "quakejs_cluster" {
  name = "quakejs-cluster"
}

data "template_file" "gameServerTemplate" {
  template = file("./ecs/taskdefinition.json.tpl")
  vars = {
    name   = var.gameserver_name_container
    port   = var.game_server_port
    cpu    = var.game_server_cpu
    ram    = var.game_server_ram
    region = var.region
    image  = var.game_server_image
  }
}

resource "aws_ecs_task_definition" "game_server_task_definition" {
  family                   = "quakejs"
  execution_role_arn       = var.task_execution_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.game_server_cpu
  memory                   = var.game_server_ram
  container_definitions    = data.template_file.gameServerTemplate.rendered
}

resource "aws_security_group" "sg_game_server_ecs" {
  name   = "sg_${var.gameserver_name_container}_ecs"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


}


resource "aws_ecs_service" "game_server_service" {
  name            = "${var.gameserver_name_container}-service"
  cluster         = aws_ecs_cluster.quakejs_cluster.id
  task_definition = aws_ecs_task_definition.game_server_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.sg_game_server_ecs.id]
    subnets          = [var.private_subnet_id_a, var.private_subnet_id_b]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_game_server_arn
    container_name   = var.gameserver_name_container
    container_port   = var.game_server_port
  }
}
