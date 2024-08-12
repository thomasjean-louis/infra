variable "app_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

resource "aws_ecs_cluster" "game_cluster" {
  name = "${var.app_name}-cluster-${var.deployment_branch}"

  tags = {
    Name = "ecs_cluster_${var.deployment_branch}"
  }
}


output "cluster_id" {
  value = aws_ecs_cluster.game_cluster.id
}

output "cluster_name" {
  value = aws_ecs_cluster.game_cluster.name
}
