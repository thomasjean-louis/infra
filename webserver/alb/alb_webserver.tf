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

variable "web_server_port" {
  type = number
}


variable "web_server_name_container" {
    type = string
}

resource "aws_security_group" "sg_alb" {
  name        = "sg_alb"
  description = "ALB security group"
  vpc_id      = var.vpc_id

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



resource "aws_lb" "alb_web_server" {    
  name               = "quakejs-alb-${var.web_server_name_container}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [var.public_subnet_id_a, var.public_subnet_id_b]

}

resource "aws_alb_target_group" "web_server_target_group" {
  name        = "target-group-${var.web_server_name_container}"
  port        = var.web_server_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

}

output "target_group_web_server_arn" {
  value = aws_alb_target_group.web_server_target_group.arn
}

resource "aws_alb_listener" "game_server_alb_listener" {
  load_balancer_arn = aws_lb.alb_web_server.arn
  port              = var.web_server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.web_server_target_group.arn
    type             = "forward"
  }

}

