variable "name_container" {
  type = string
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/${var.name_container}"
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name = var.name_container
  log_group_name = aws_cloudwatch_log_group.log_group.name
}