locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  sqs_queue_a_name = "${var.project_name}-${var.environment}-iwaosan-queue-a"
  sqs_queue_b_name = "${var.project_name}-${var.environment}-iwaosan-queue-b"
  sns_topic_name   = "${var.project_name}-${var.environment}-iwaosan-topic"
}