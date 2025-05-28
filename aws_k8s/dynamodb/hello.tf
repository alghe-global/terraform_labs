terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.98.0"
    }
  }
}

resource "aws_dynamodb_table" "hello" {
  hash_key = "message"
  name     = "hello"
  read_capacity = 10
  write_capacity = 10

  attribute {
    name = "message"
    type = "S"
  }

  tags = {
    Name = "dynamodb-table"
    Environment = "prod"
  }
}

resource "aws_dynamodb_table_item" "message" {
  table_name = aws_dynamodb_table.hello.name
  hash_key   = aws_dynamodb_table.hello.hash_key

  item = <<ITEM
{
  "message": {"S": "Hello, world!"}
}
ITEM
}