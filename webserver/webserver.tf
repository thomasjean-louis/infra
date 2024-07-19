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

variable "gameserver_address" {
  type = string
}

variable "target_group_web_server_arn" {
  type = string
}

variable "web_server_name_container" {
  type = string
}

variable "web_server_cpu" {
  type = string
}

variable "web_server_ram" {
  type = string
}

variable "web_server_port" {
  type = string
}

variable "web_server_image" {
  type = string
}

data "template_file" "webServerTemplate" {
  template = file("./ecs/taskdefinition.json.tpl")
  vars = {
    name                  = var.web_server_name_container
    port                  = var.web_server_port
    cpu                   = var.web_server_cpu
    ram                   = var.web_server_ram
    region                = var.region
    image                 = var.web_server_image
    contentserver_address = var.content_server_address
    gameserver_address    = var.gameserver_address
  }
}

resource "aws_ecs_task_definition" "web_server_task_definition" {
  family                   = "quakejs-${var.web_server_name_container}"
  execution_role_arn       = var.task_execution_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.web_server_cpu
  memory                   = var.web_server_ram
  container_definitions    = data.template_file.webServerTemplate.rendered
}

resource "aws_security_group" "sg_web_server_ecs" {
  name   = "sg_${var.web_server_name_container}_ecs"
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


//ECS Service will be created during runtime
/*
resource "aws_ecs_service" "web_server_service" {
  name                    = "${var.web_server_name_container}-service"
  cluster                 = var.cluster_id
  task_definition         = aws_ecs_task_definition.web_server_task_definition.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_ecs_managed_tags = true
  wait_for_steady_state   = true

  network_configuration {
    security_groups  = [aws_security_group.sg_web_server_ecs.id]
    subnets          = [var.private_subnet_id_a, var.private_subnet_id_b]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_web_server_arn
    container_name   = var.web_server_name_container
    container_port   = var.web_server_port
  }
}
*/
