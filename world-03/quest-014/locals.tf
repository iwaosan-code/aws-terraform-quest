locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  dynamodb_table_name       = "${var.project_name}-${var.environment}-quest014-table"
  lambda_function_role_name = "${var.project_name}-${var.environment}-quest014-lambda-role"
  lambda_function_name      = "${var.project_name}-${var.environment}-quest014-lambda"
}