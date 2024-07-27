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

variable "proxy_server_port" {
  type = number
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
    VpcId = var.vpc_id

    HostedZoneName = var.hosted_zone_name
    RandomString   = random_string.random_string.result

    HostedZoneId       = data.aws_route53_zone.project_route_zone.zone_id
    SubnetIdA          = var.subnet_id_a
    SubnetIdB          = var.subnet_id_b
    SecurityGroupAlbId = var.security_group_alb_id
    ProxyServerPort    = var.proxy_server_port


  }

  template_body = file("${path.module}/cloud_formation_game_server_stack.yml")

}
