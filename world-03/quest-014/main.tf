# DynamoDB 作成
resource "aws_dynamodb_table" "main" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "adventure_id"
  range_key    = "recorded_at"

  attribute {
    name = "adventure_id"
    type = "S"
  }

  attribute {
    name = "recorded_at"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = local.common_tags
}

# Lambda 関数作成
resource "aws_iam_role" "lambda" {
  name = local.lambda_function_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file  = "${path.module}/mylambda_function.py"
  output_path = "${path.module}/mylambda_function.zip"
}

resource "aws_lambda_function" "main" {
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = "mylambda_function.lambda_handler"
  runtime       = "python3.13"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = local.common_tags
}

resource "aws_lambda_event_source_mapping" "dynamodb" {
  event_source_arn  = aws_dynamodb_table.main.stream_arn
  function_name     = aws_lambda_function.main.arn
  starting_position = "LATEST"
  batch_size        = 10
}