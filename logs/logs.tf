resource "aws_cloudwatch_log_group" "gameserver_log_group" {
  name = "/ecs/gameserver"
}

resource "aws_cloudwatch_log_stream" "gameserver_log_stream" {
  name = "gameserver"
  log_group_name = aws_cloudwatch_log_group.gameserver_log_group.name
}