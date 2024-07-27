variable "vpc_id" {
  type = string
}

variable "hosted_zone_name" {
  type = string
}


variable "subnet_id_a" {
  type = string
}

variable "subnet_id_b" {
  type = string
}

variable "security_group_alb_id" {
  type = string
}


## Data

data "aws_route53_zone" "project_route_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

## Ressources
resource "random_string" "random_string" {
  length  = 16
  special = false
  numeric = false
}

resource "aws_cloudformation_stack" "game_server_stack" {
  name = "game-server-stack-${random_string.random_string.result}"

  parameters = {
    vpc_id = var.vpc_id

    hosted_zone_name = var.hosted_zone_name
    random_string    = random_string.random_string.result

    hosted_zone_id        = data.aws_route53_zone.project_route_zone.zone_id
    subnet_id_a           = var.subnet_id_a
    subnet_id_b           = var.subnet_id_b
    security_group_alb_id = var.security_group_alb_id
  }

  template_body = file("${path.module}/cloud_formation.yml")

}
