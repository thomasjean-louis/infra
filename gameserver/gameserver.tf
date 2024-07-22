variable "app_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "content_server_address" {
  type = string
}

## Network
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

variable "private_subnet_id_a" {
  type = string
}

variable "private_subnet_id_b" {
  type = string
}

## Container

variable "target_group_game_server_arn" {
  type = string
}

variable "game_server_name_container" {
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

data "template_file" "gameServerTemplate" {
  template = file("./ecs/taskdefinition.json.tpl")
  vars = {
    name                  = var.game_server_name_container
    port                  = var.game_server_port
    cpu                   = var.game_server_cpu
    ram                   = var.game_server_ram
    region                = var.region
    image                 = var.game_server_image
    contentserver_address = var.content_server_address
    gameserver_address    = "localhost"
  }
}


resource "aws_ecs_task_definition" "game_server_task_definition" {
  family                   = "${var.app_name}-${var.game_server_name_container}"
  execution_role_arn       = var.task_execution_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.game_server_cpu
  memory                   = var.game_server_ram
  container_definitions    = data.template_file.gameServerTemplate.rendered
}

resource "aws_security_group" "sg_game_server_ecs" {
  name   = "sg_${var.game_server_name_container}_ecs"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27960
    to_port     = 27960
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 27960
    to_port     = 27960
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "security_group_game_server_task" {
  value = aws_security_group.sg_game_server_ecs.id
}

output "task_definition_game_server" {
  value = aws_ecs_task_definition.game_server_task_definition.id
}



