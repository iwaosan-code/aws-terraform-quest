locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  bucket_name = "${var.project_name}-${var.environment}-iwaosan-bucket"
}