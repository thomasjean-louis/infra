variable "gameserver_name_container" {
  type = string
}

resource "aws_cloudwatch_log_group" "gameserver_log_group" {
  name = "/ecs/${var.gameserver_name_container}"
}

resource "aws_cloudwatch_log_stream" "gameserver_log_stream" {
  name = var.gameserver_name_container
  log_group_name = aws_cloudwatch_log_group.gameserver_log_group.name
}