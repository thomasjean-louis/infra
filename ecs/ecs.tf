variable "app_name" {

}

resource "aws_ecs_cluster" "game_cluster" {
  name = "${var.app_name}-cluster"
}


output "cluster_id" {
  value = aws_ecs_cluster.game_cluster.id
}

output "cluster_name" {
  value = aws_ecs_cluster.game_cluster.name
}
