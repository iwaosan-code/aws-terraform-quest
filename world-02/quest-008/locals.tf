locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  bucket_name                = "${var.project_name}-${var.environment}-iwaosan-bucket"
  lambda_function_name       = "${var.project_name}-${var.environment}-iwaosan-function"
  lambda_role_name           = "${var.project_name}-${var.environment}-iwaosan-role"
  lambda_s3_access_role_name = "${var.project_name}-${var.environment}-iwaosan-s3-access-role"
  sqs_queue_name             = "${var.project_name}-${var.environment}-iwaosan-queue"
}