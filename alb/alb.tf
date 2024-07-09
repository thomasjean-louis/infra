variable "vpc_id" {
  type = string
}
variable "vpc_cidr_block" {
  type = string
}
variable "public_subnet_cidr_a" {
  type = string
}
variable "public_subnet_cidr_b" {
  type = string
}

resource "aws_security_group" "sg_alb" {
    name = "sg_alb"
    description  = "ALB security group"
    vpc_id = var.vpc_id
  
}


resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sg_alb.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_lb" "alb" {
    name = "quakejs_alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.sg_alb.id]
    subnets = [var.public_subnet_cidr_a, var.public_subnet_cidr_b ]
  
}

