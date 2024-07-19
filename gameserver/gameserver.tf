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
  family                   = "quakejs-${var.game_server_name_container}"
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

// ECS Service will be created during runtime
/*
resource "aws_ecs_service" "game_server_service" {
  name                    = "${var.game_server_name_container}-service"
  cluster                 = var.cluster_id
  task_definition         = aws_ecs_task_definition.game_server_task_definition.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_ecs_managed_tags = true
  wait_for_steady_state   = true

  network_configuration {
    security_groups  = [aws_security_group.sg_game_server_ecs.id]
    subnets          = [var.private_subnet_id_a, var.private_subnet_id_b]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_game_server_arn
    container_name   = var.game_server_name_container
    container_port   = var.game_server_port
  }
}
*/

# Get private IP of running gameserver container
/*data "aws_network_interface" "interface_tags" {
  depends_on = [aws_ecs_service.game_server_service]
  filter {
    name   = "tag:aws:ecs:serviceName"
    values = ["${var.game_server_name_container}-service"]
  }
}

output "game_server_address" {
  value = data.aws_network_interface.interface_tags.private_ip
}
*/
