terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3バケットを作成
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

# S3のパブリックアクセスをブロックする設定
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3のイベント通知設定を作成
resource "aws_s3_bucket_notification" "this" {
  bucket      = aws_s3_bucket.this.id
  eventbridge = true
}

# Pythonコードをzipで固める
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/mylambda_function.py"
  output_path = "${path.module}/mylambda_function.zip"
}

# Lambda用IAMロール作成
resource "aws_iam_role" "lambda_role" {
  name = local.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda関数にS3へのアクセス権を付与
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = local.lambda_s3_access_role_name
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

# CloudWatch Logsへのアクセス権限を付与
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda関数作成
resource "aws_lambda_function" "this" {
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "mylambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# EventBridgeでS3バケットのオブジェクト作成イベントをトリガーとしてLambda関数を呼び出す
resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = local.eventbridge_rule_name
  description = "Trigger Lambda function when an object is created in the S3 bucket"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    resources   = [aws_s3_bucket.this.arn]
    detail = {
      object = {
        key = [{
          suffix = ".txt"
        }]
      }
    }
  })
}

# Lambda関数をEventBridgeルールにターゲットとして追加
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
}

# Lambda関数がEventBridgeルールから呼び出されるための権限を付与
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.s3_object_created.arn
}

# EventBridgeルールのログをCloudWatch Logsに出力するための設定
resource "aws_cloudwatch_event_target" "eventbridge_logs" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "eventbridge-logs"
  arn       = aws_cloudwatch_log_group.eventbridge_logs.arn
}

# CloudWatch Logsのロググループを作成
resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name              = local.eventbridge_log_group_name
  retention_in_days = 14
}

# CloudWatch LogsにEventBridgeからのログ出力を許可する
resource "aws_cloudwatch_log_resource_policy" "eventbridge_logs_policy" {
  policy_name = local.eventbridge_logs_policy_name
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToWriteLogs"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.eventbridge_logs.arn}:*"
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.s3_object_created.arn
          }
        }
      }
    ]
  })
}