variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet_id_a" {
  type = string
}

variable "public_subnet_id_b" {
  type = string
}

variable "game_server_port" {
  type = number
}


variable "game_server_name_container" {
  type = string
}

resource "aws_security_group" "sg_alb" {
  name        = "sg_alb_${var.game_server_name_container}"
  description = "ALB security group"
  vpc_id      = var.vpc_id

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



resource "aws_lb" "alb_game_server" {
  name               = "${app_name}-alb-${var.game_server_name_container}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [var.public_subnet_id_a, var.public_subnet_id_b]

}

resource "aws_alb_target_group" "gameserver_target_group" {
  name        = "target-group-${var.game_server_name_container}"
  port        = var.game_server_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

}

output "target_group_game_server_arn" {
  value = aws_alb_target_group.gameserver_target_group.arn
}

resource "aws_alb_listener" "game_server_alb_listener" {
  load_balancer_arn = aws_lb.alb_game_server.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gameserver_target_group.arn
    type             = "forward"
  }

}

output "alb_game_server_DNS" {
  value = aws_lb.alb_game_server.dns_name
}


