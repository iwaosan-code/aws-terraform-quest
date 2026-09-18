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

# Pythonコードをzipで固める
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/mylambda_function.py"
  output_path = "${path.module}/mylambda_function.zip"
}

# Lambda用IAMロール作成
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

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

# CloudWatch Logsへのアクセス権限を付与
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda関数作成
resource "aws_lambda_function" "this" {
  function_name = "${var.project_name}-${var.environment}-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "mylambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}