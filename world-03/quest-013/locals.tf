locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  bucket_name           = "${var.project_name}-${var.environment}-quest013-bucket"
  glue_database_name    = "${var.project_name}_${var.environment}_quest013"
  glue_table_name       = "adventure"
  glue_table_serde_name = "adventure-serde"
}