resource "aws_ecs_cluster" "quakejs_cluster" {
  name = "quakejs-cluster"
}


output "cluster_id" {
  value = aws_ecs_cluster.quakejs_cluster.id
}

output "cluster_name" {
  value = aws_ecs_cluster.quakejs_cluster.name
}
