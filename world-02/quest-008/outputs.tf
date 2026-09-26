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

output "sqs_queue_url" {
  value = aws_sqs_queue.this.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.this.arn
}