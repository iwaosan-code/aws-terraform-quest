locals {
  prefix = "${var.project_name}-${var.environment}-quest-011"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  dynamodb_table_name = "${local.prefix}-records"
  dynamodb_GSI_name   = "${local.prefix}-records-global-secondary-index"
}