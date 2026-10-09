data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  prefix = "${var.project_name}-${var.environment}-boss-002"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket_prefix = "${local.prefix}-"
  force_destroy = true
  tags          = local.tags
}
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sns_topic" "events" {
  name = "${local.prefix}-events"
  tags = local.tags
}

data "aws_iam_policy_document" "sns_from_s3" {
  statement {
    sid       = "AllowS3Publish"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.events.arn]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.uploads.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
resource "aws_sns_topic_policy" "events" {
  arn    = aws_sns_topic.events.arn
  policy = data.aws_iam_policy_document.sns_from_s3.json
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  topic {
    topic_arn     = aws_sns_topic.events.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }
  depends_on = [aws_sns_topic_policy.events]
}

resource "aws_sqs_queue" "dlq" {
  for_each                  = toset(["content", "audit"])
  name                      = "${local.prefix}-${each.key}-dlq"
  message_retention_seconds = 1209600
  tags                      = local.tags
}
resource "aws_sqs_queue" "work" {
  for_each                   = toset(["content", "audit"])
  name                       = "${local.prefix}-${each.key}"
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 5
  })
  tags = local.tags
}

data "aws_iam_policy_document" "sqs_from_sns" {
  for_each = aws_sqs_queue.work
  statement {
    sid       = "AllowTopicSendMessage"
    actions   = ["sqs:SendMessage"]
    resources = [each.value.arn]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}
resource "aws_sqs_queue_policy" "work" {
  for_each  = aws_sqs_queue.work
  queue_url = each.value.id
  policy    = data.aws_iam_policy_document.sqs_from_sns[each.key].json
}
resource "aws_sns_topic_subscription" "work" {
  for_each             = aws_sqs_queue.work
  topic_arn            = aws_sns_topic.events.arn
  protocol             = "sqs"
  endpoint             = each.value.arn
  raw_message_delivery = true
  depends_on           = [aws_sqs_queue_policy.work]
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda" {
  for_each           = aws_sqs_queue.work
  name               = "${local.prefix}-${each.key}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.tags
}
resource "aws_iam_role_policy_attachment" "basic" {
  for_each   = aws_iam_role.lambda
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda" {
  for_each = aws_sqs_queue.work
  statement {
    sid       = "ReadQueue"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [each.value.arn]
  }
  dynamic "statement" {
    for_each = each.key == "content" ? [1] : []
    content {
      sid       = "ReadUploadedFiles"
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.uploads.arn}/*"]
    }
  }
}
resource "aws_iam_role_policy" "lambda" {
  for_each = aws_iam_role.lambda
  name     = "${local.prefix}-${each.key}-access"
  role     = each.value.id
  policy   = data.aws_iam_policy_document.lambda[each.key].json
}

data "archive_file" "lambda" {
  for_each    = toset(["content", "audit"])
  type        = "zip"
  source_file = "${path.module}/lambda_${each.key}.py"
  output_path = "${path.module}/lambda_${each.key}.zip"
}
resource "aws_lambda_function" "worker" {
  for_each         = aws_iam_role.lambda
  function_name    = "${local.prefix}-${each.key}"
  role             = each.value.arn
  runtime          = "python3.12"
  handler          = "lambda_${each.key}.lambda_handler"
  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256
  timeout          = 5
  tags             = local.tags
  depends_on       = [aws_iam_role_policy_attachment.basic, aws_iam_role_policy.lambda]
}
resource "aws_lambda_event_source_mapping" "work" {
  for_each                = aws_sqs_queue.work
  event_source_arn        = each.value.arn
  function_name           = aws_lambda_function.worker[each.key].arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
  depends_on              = [aws_iam_role_policy.lambda]
}
