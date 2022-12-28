resource "aws_dynamodb_table" "db" {
  name = "VisitorsTF"
  hash_key = "IP"
  range_key = "UA"
  read_capacity = 2
  write_capacity = 2

  attribute {
    name = "IP"
    type = "S"
  }

  attribute {
    name = "UA"
    type = "S"
  }
  
}