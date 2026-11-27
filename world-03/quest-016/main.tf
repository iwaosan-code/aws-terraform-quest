# Secrets Manager のシークレットを作成する
resource "aws_secretsmanager_secret" "lambda_secret" {
  name                    = var.secret_name
  recovery_window_in_days = 0

  tags = local.common_tags
}

# Secrets Manger に値を格納する
resource "aws_secretsmanager_secret_version" "lambda_secret_version" {
  secret_id = aws_secretsmanager_secret.lambda_secret.id
  secret_string = jsonencode({
    username = "myuser"
    password = "mypassword"
  })
}

# Lambda から Secrets Manager のシークレットにアクセスするための IAM ポリシーを作成する
resource "aws_iam_policy" "lambda_secrets_manager_policy" {
  name        = local.lambda_secrets_manager_policy_name
  description = "IAM policy for Lambda to access Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.lambda_secret.arn
      }
    ]
  })
}

# Lambada に CloudWatch Logs へのアクセス権限を付与する IAM ポリシーを作成する
resource "aws_iam_policy" "lambda_cloudwatch_logs_policy" {
  name        = local.lambda_cloudwatch_logs_policy_name
  description = "IAM policy for Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda 用 IAM ロールを作成する
resource "aws_iam_role" "lambda_execution_role1" {
  name = local.lambda_execution_role_name1

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

resource "aws_iam_role" "lambda_execution_role2" {
  name = local.lambda_execution_role_name2

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

# Lmamda 用 IAM ロールに ポリシーを付与する
resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_policy_attachment1" {
  role       = aws_iam_role.lambda_execution_role1.name
  policy_arn = aws_iam_policy.lambda_secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_policy_attachment1" {
  role       = aws_iam_role.lambda_execution_role1.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_policy_attachment2" {
  role       = aws_iam_role.lambda_execution_role2.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs_policy.arn
}

# Pythonコードをzipで固める
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/mylambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda 関数の作成
resource "aws_lambda_function" "my_lambda1" {
  function_name = local.lambda_function_name1
  role          = aws_iam_role.lambda_execution_role1.arn
  handler       = "mylambda_function.lambda_handler"
  runtime       = "python3.12"

  # Lambda 関数のコードを zip ファイルとして指定
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.lambda_secret.name
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_function" "my_lambda2" {
  function_name = local.lambda_function_name2
  role          = aws_iam_role.lambda_execution_role2.arn
  handler       = "mylambda_function.lambda_handler"
  runtime       = "python3.12"

  # Lambda 関数のコードを zip ファイルとして指定
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.lambda_secret.name
    }
  }

  tags = local.common_tags
}