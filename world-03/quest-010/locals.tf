locals {
  prefix = "${var.project_name}-${var.environment}-quest-010"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  dynamodb_table_name = "${local.prefix}-items"
}