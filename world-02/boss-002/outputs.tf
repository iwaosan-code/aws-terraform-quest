output "bucket_name" { value = aws_s3_bucket.uploads.id }
output "sns_topic_arn" { value = aws_sns_topic.events.arn }
output "work_queue_urls" { value = { for k, q in aws_sqs_queue.work : k => q.id } }
output "dlq_urls" { value = { for k, q in aws_sqs_queue.dlq : k => q.id } }
