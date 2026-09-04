variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_subnets" {
  description = "Public subnet CIDRs by availability zone"
  type        = map(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs by availability zone"
  type        = map(string)
}