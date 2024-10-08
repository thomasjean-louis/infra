# variable "vpc_id" {
#   type = string
# }

# variable "hosted_zone_name" {
#   type = string
# }


# variable "public_subnet_id_a" {
#   type = string
# }

# variable "public_subnet_id_b" {
#   type = string
# }

# variable "security_group_alb_id" {
#   type = string
# }

# variable "proxy_server_port" {
#   type = number
# }

# variable "private_subnet_id_a" {
#   type = string
# }

# variable "private_subnet_id_b" {
#   type = string
# }

# variable "task_definition_arn" {
#   type = string
# }

# variable "proxy_server_name_container" {
#   type = string
# }

# variable "cluster_id" {
#   type = string
# }

# variable "security_group_game_server_task_id" {
#   type = string
# }

variable "region" {
  type = string
}

variable "s3-bucket-name" {
  type = string
}

resource "random_string" "random_string" {
  length  = 16
  special = false
  numeric = false
}

# CF template stored in S3. Need to add etag parameter, otherwise CF template won't be updated
resource "aws_s3_object" "cloud_formation_game_server_stack" {
  bucket = var.s3-bucket-name
  key    = "cf-templates/cloud_formation_game_server_stack.yml"
  source = "${path.module}/cloud_formation_game_server_stack.yml"
  etag   = filemd5("${path.module}/cloud_formation_game_server_stack.yml")
}



output "create_game_stack_cf_template_url" {
  value = "https://${aws_s3_object.cloud_formation_game_server_stack.bucket}.s3.${var.region}.amazonaws.com/${aws_s3_object.cloud_formation_game_server_stack.key}"
}

output "s3_bucket_cf_templates" {
  value = aws_s3_object.cloud_formation_game_server_stack.bucket
}

# Add CloudFormation template in S3 bucket


## Data

# data "aws_route53_zone" "project_route_zone" {
#   name         = var.hosted_zone_name
#   private_zone = false
# }

# ## Ressources
# resource "random_string" "random_string" {
#   length  = 16
#   special = false
#   numeric = false
# }

# resource "aws_cloudformation_stack" "game_server_stack" {
#   name = "game-server-stack-${random_string.random_string.result}"

#   parameters = {
#     VpcId = var.vpc_id

#     HostedZoneName = var.hosted_zone_name
#     RandomString   = random_string.random_string.result

#     HostedZoneId       = data.aws_route53_zone.project_route_zone.zone_id
#     PublicSubnetIdA    = var.public_subnet_id_a
#     PublicSubnetIdB    = var.public_subnet_id_b
#     SecurityGroupAlbId = var.security_group_alb_id
#     ProxyServerPort    = var.proxy_server_port

#     ClusterId                     = var.cluster_id
#     SecurityGroupGameServerTaskId = var.security_group_game_server_task_id
#     PrivateSubnetA                = var.private_subnet_id_a
#     PrivateSubnetB                = var.private_subnet_id_b
#     TaskDefinitionArn             = var.task_definition_arn
#     ProxyServerNameContainer      = var.proxy_server_name_container

#   }

#   template_body = file("${path.module}/cloud_formation_game_server_stack.yml")

# }
