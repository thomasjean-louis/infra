
variable "gamestacks_table_name" {
  type = string
}

variable "game_stacks_id_column_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

resource "aws_dynamodb_table" "gamestacks" {
  name         = var.gamestacks_table_name
  hash_key     = var.game_stacks_id_column_name
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = var.game_stacks_id_column_name
    type = "S"
  }

}

resource "aws_dynamodb_table_item" "gamestack_01" {
  count      = (var.deployment_branch == "dev") ? 1 : 0
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
    "IsActive" : {
      "BOOL" : true
    },
    "ServerStatus" : {
      "S" : "running"
    },
    "StopServerTime" : {
      "S" : ""
    },
    "Message" : {
      "S" : "stack 01 message"
    },

  })
}

resource "aws_dynamodb_table_item" "gamestack_02" {
  count = (var.deployment_branch == "dev") ? 1 : 0

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
    "IsActive" : {
      "BOOL" : true
    },
    "ServerStatus" : {
      "S" : "stopped"
    },
    "StopServerTime" : {
      "S" : ""
    },
    "Message" : {
      "S" : "stack 02 message"
    },

  })
}

resource "aws_dynamodb_table_item" "gamestack_03" {
  count = (var.deployment_branch == "dev") ? 1 : 0

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
    "IsActive" : {
      "BOOL" : false
    },
    "ServerStatus" : {
      "S" : "running"
    },
    "StopServerTime" : {
      "S" : ""
    },
    "Message" : {
      "S" : "stack 03 message"
    },
  })
}

output "gamestacks_table_name" {
  value = var.gamestacks_table_name
}
