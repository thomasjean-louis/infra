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

resource "aws_security_group" "sg_alb" {
  name        = "sg_alb"
  description = "ALB security group"
  vpc_id      = var.vpc_id

}


resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sg_alb.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_lb" "alb" {
  name               = "quakejs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [var.public_subnet_id_a, var.public_subnet_id_b]

}

resource "aws_alb_target_group" "gameserver_target_group" {
  name        = "gameserver-target-group"
  port        = var.game_server_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

output "target_group_game_server_arn" {
  value = aws_alb_target_group.gameserver_target_group.arn
}

resource "aws_alb_listener" "game_server_alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.game_server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gameserver_target_group.arn
    type             = "forward"
  }

}


