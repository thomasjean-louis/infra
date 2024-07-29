
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
    type = "S"
  }

}

resource "aws_dynamodb_table_item" "gamestack_01" {

  table_name = aws_dynamodb_table.gamestacks.name
  hash_key   = aws_dynamodb_table.gamestacks.hash_key
  item = jsonencode({
    "ID" : {
      "S" : "gamestack_01"
    },
    "Capacity" : {
      "N" : "4"
    },
    "ServerLink" : {
      "S" : "server_a.com"
    },
  })
}

resource "aws_dynamodb_table_item" "gamestack_02" {

  table_name = aws_dynamodb_table.gamestacks.name
  hash_key   = aws_dynamodb_table.gamestacks.hash_key
  item = jsonencode({
    "ID" : {
      "S" : "gamestack_02"
    },
    "Capacity" : {
      "N" : "7"
    },
    "ServerLink" : {
      "S" : "server_b.com"
    },
  })
}

resource "aws_dynamodb_table_item" "gamestack_03" {

  table_name = aws_dynamodb_table.gamestacks.name
  hash_key   = aws_dynamodb_table.gamestacks.hash_key
  item = jsonencode({
    "ID" : {
      "S" : "gamestack_03"
    },
    "Capacity" : {
      "N" : "2"
    },
    "ServerLink" : {
      "S" : "server_c.com"
    },
  })
}
