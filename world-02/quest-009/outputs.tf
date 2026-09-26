output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}

output "sqs_queue_a_url" {
  value = aws_sqs_queue.queue_a.url
}

output "sqs_queue_b_url" {
  value = aws_sqs_queue.queue_b.url
}
