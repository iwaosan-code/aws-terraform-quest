locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  vpc_name        = "${var.project_name}-${var.environment}-vpc"
  igw_name        = "${var.project_name}-${var.environment}-igw"
  public_rt_name  = "${var.project_name}-${var.environment}-public-rt"
  private_rt_name = "${var.project_name}-${var.environment}-private-rt"

  public_sg_name = "${var.project_name}-${var.environment}-public-sg"
  ec2_sg_name    = "${var.project_name}-${var.environment}-ec2-sg"
  alb_sg_name    = "${var.project_name}-${var.environment}-alb-sg"

  ec2_name = "${var.project_name}-${var.environment}-ec2"
  alb_name = "${var.project_name}-${var.environment}-alb"
}