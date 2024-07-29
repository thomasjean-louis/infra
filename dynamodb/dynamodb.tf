
variable "gamestacks_table_name" {
  type = string
}

variable "gamestack_id" {
  type = string
}

resource "aws_dynamodb_table" "gamestacks" {
  name         = var.gamestacks_table_name
  hash_key     = var.gamestack_id
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = var.gamestack_id
    type = "N"
  }

}

resource "aws_dynamodb_table_item" "gamestack_01" {

  table_name = aws_dynamodb_table.gamestacks.name
  hash_key   = aws_dynamodb_table.gamestacks.hash_key
  item       = <<EOF
{
"ID" : "GameStack_01"
"Capacity" : "4"
"ServerLink": "server_A.com
}
    EOF
}

resource "aws_dynamodb_table_item" "gamestack_02" {

  table_name = aws_dynamodb_table.gamestacks.name
  hash_key   = aws_dynamodb_table.gamestacks.hash_key
  item       = <<EOF
{
"ID" : "GameStack_02"
"Capacity" : "5"
"ServerLink": "server_B.com
}
    EOF
}

resource "aws_dynamodb_table_item" "gamestack_03" {

  table_name = aws_dynamodb_table.gamestacks.name
  hash_key   = aws_dynamodb_table.gamestacks.hash_key
  item       = <<EOF
{
"ID" : "GameStack_03"
"Capacity" : "2"
"ServerLink": "server_C.com
}
    EOF
}
