output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.s3_object_created.name
}

output "eventbridge_rule_arn" {
  value = aws_cloudwatch_event_rule.s3_object_created.arn
}

output "eventbridge_logs_log_group_arn" {
  value = aws_cloudwatch_log_group.eventbridge_logs.arn
}