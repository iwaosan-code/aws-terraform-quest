locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lambda_execution_role_name1        = "${var.project_name}-${var.environment}-quest016-lambda-execution-role1"
  lambda_execution_role_name2        = "${var.project_name}-${var.environment}-quest016-lambda-execution-role2"
  lambda_secrets_manager_policy_name = "${var.project_name}-${var.environment}-quest016-lambda-secrets-manager-policy"
  lambda_cloudwatch_logs_policy_name = "${var.project_name}-${var.environment}-quest016-lambda-cloudwatch-logs-policy"
  lambda_function_name1              = "${var.project_name}-${var.environment}-quest016-my-lambda1"
  lambda_function_name2              = "${var.project_name}-${var.environment}-quest016-my-lambda2"
}