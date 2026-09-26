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

# SNSトピックを作成
resource "aws_sns_topic" "this" {
  name = local.sns_topic_name

  tags = local.common_tags
}

# SNS通知をSQSキューに送信するためのサブスクリプションを作成
resource "aws_sns_topic_subscription" "queue_a" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue_a.arn

  # SQS側の許可設定後にSubscriptionを作成
  depends_on = [aws_sqs_queue_policy.allow_sns_queue_a]

  # 特定のSNSメッセージのみを受信する
  filter_policy = jsonencode({
    eventType = ["a"]
  })
}

resource "aws_sns_topic_subscription" "queue_b" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue_b.arn

  # SQS側の許可設定後にSubscriptionを作成
  depends_on = [aws_sqs_queue_policy.allow_sns_queue_b]
}

# SQSキューを作成
resource "aws_sqs_queue" "queue_a" {
  name = local.sqs_queue_a_name

  tags = local.common_tags
}

resource "aws_sqs_queue" "queue_b" {
  name = local.sqs_queue_b_name

  tags = local.common_tags
}

# SQSキューにSNSからのメッセージを受信するためのポリシーを設定
resource "aws_sqs_queue_policy" "allow_sns_queue_a" {
  queue_url = aws_sqs_queue.queue_a.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublishToQueueA"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue_a.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.this.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "allow_sns_queue_b" {
  queue_url = aws_sqs_queue.queue_b.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublishToQueueB"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue_b.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.this.arn
          }
        }
      }
    ]
  })
}