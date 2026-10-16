resource "aws_dynamodb_table" "records" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "adventurer_id"
  range_key    = "recorded_at"

  attribute {
    name = "adventurer_id"
    type = "S"
  }

  attribute {
    name = "recorded_at"
    type = "S"
  }

  tags = local.common_tags
}