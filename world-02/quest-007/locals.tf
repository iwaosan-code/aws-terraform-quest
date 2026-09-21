locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  bucket_name                  = "${var.project_name}-${var.environment}-iwaosan-bucket"
  lambda_function_name         = "${var.project_name}-${var.environment}-iwaosan-function"
  lambda_role_name             = "${var.project_name}-${var.environment}-iwaosan-role"
  lambda_s3_access_role_name   = "${var.project_name}-${var.environment}-iwaosan-s3-access-role"
  eventbridge_rule_name        = "${var.project_name}-${var.environment}-iwaosan-eventbridge-rule"
  eventbridge_logs_role_name   = "${var.project_name}-${var.environment}-iwaosan-eventbridge-logs-role"
  eventbridge_logs_policy_name = "${var.project_name}-${var.environment}-iwaosan-eventbridge-logs-policy"
  eventbridge_log_group_name   = "/aws/events/${var.project_name}-${var.environment}-iwaosan-eventbridge-rule"
}