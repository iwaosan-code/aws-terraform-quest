# VPC 作成
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags
}

# Private Subnet 作成
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags              = local.common_tags
}

# Private Subnet のルートテーブル作成
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# SSM 用の VPC エンドポイント作成
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm.id]
  subnet_ids          = values(aws_subnet.private)[*].id
  private_dns_enabled = true

  tags = local.common_tags
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm.id]
  subnet_ids          = values(aws_subnet.private)[*].id
  private_dns_enabled = true

  tags = local.common_tags
}

# VPC エンドポイントのセキュリティグループ作成
resource "aws_security_group" "ssm" {
  name        = local.ssm_sg_name
  description = "Security group for SSM VPC endpoint"
  vpc_id      = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "ssm_ingress" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.ssm.id
  referenced_security_group_id = aws_security_group.ec2.id
}

# EC2 作成
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = values(aws_subnet.private)[0].id
  vpc_security_group_ids = [
    aws_security_group.ec2.id,
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name

  tags = local.common_tags
}

# EC2 用のセキュリティグループ作成
resource "aws_security_group" "ec2" {
  name        = local.ec2_sg_name
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# EC2 用 IAM ロール作成
resource "aws_iam_role" "ec2_ssm_role" {
  name = local.ec2_ssm_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = local.ec2_ssm_instance_profile_name
  role = aws_iam_role.ec2_ssm_role.name
}

# RDS (PostgreSQL) 用 Security Group 作成
resource "aws_security_group" "rds" {
  name        = local.rds_sg_name
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress" {
  security_group_id = aws_security_group.rds.id

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id
}

# DB サブネットグループ作成
resource "aws_db_subnet_group" "rds" {
  name        = local.rds_subnet_group_name
  description = "Subnet group for RDS instance"
  subnet_ids  = values(aws_subnet.private)[*].id

  tags = local.common_tags
}

# RDS (PostgreSQL) 作成
data "aws_rds_engine_version" "postgres" {
  engine  = "postgres"
  version = "15"
  latest  = true
}

resource "aws_db_instance" "rds" {
  identifier              = local.rds_instance_name
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = data.aws_rds_engine_version.postgres.version
  instance_class          = "db.t3.micro"
  username                = var.rds_username
  password                = var.rds_password
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  multi_az                = false
  publicly_accessible     = false
  storage_type            = "gp3"
  deletion_protection     = false
  backup_retention_period = 1
  apply_immediately       = true
}

# S3 Gateway VPC エンドポイント作成
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = local.common_tags
}