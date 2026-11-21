locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ssm_sg_name                   = "${var.project_name}-${var.environment}-quest015-ssm-sg"
  ssm_messages_sg_name          = "${var.project_name}-${var.environment}-quest015-ssm-messages-sg"
  ec2_sg_name                   = "${var.project_name}-${var.environment}-quest015-ec2-sg"
  ec2_ssm_role_name             = "${var.project_name}-${var.environment}-quest015-ec2-ssm-role"
  ec2_ssm_policy_name           = "${var.project_name}-${var.environment}-quest015-ec2-ssm-policy"
  ec2_ssm_instance_profile_name = "${var.project_name}-${var.environment}-quest015-ec2-ssm-instance-profile"
  rds_sg_name                   = "${var.project_name}-${var.environment}-quest015-rds-sg"
  rds_subnet_group_name         = "${var.project_name}-${var.environment}-quest015-rds-subnet-group"
  rds_instance_name             = "${var.project_name}-${var.environment}-quest015-rds"
}