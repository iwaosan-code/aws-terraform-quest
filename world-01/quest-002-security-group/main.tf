terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "aws" {
    region = var.region_name
}

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

    tags = merge(var.tags, {
        Name = local.vpc_name
    })
}

resource "aws_subnet" "public" {
    for_each = var.public_subnets

    vpc_id                  = aws_vpc.main.id
    cidr_block              = each.value
    availability_zone       = each.key
    map_public_ip_on_launch = true

    tags = merge(var.tags, {
        Name = "public-${each.key}"
    })
}

resource "aws_subnet" "private" {
    for_each = var.private_subnets

    vpc_id                  = aws_vpc.main.id
    cidr_block              = each.value
    availability_zone       = each.key

    tags = merge(var.tags, {
        Name = "private-${each.key}"
    })
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = merge(var.tags, {
        Name = local.igw_name
    })
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = merge(var.tags, {
        Name = local.public_rt_name
    })
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = merge(var.tags, {
        Name = local.private_rt_name
    })
}

resource "aws_route_table_association" "public" {
    for_each = aws_subnet.public

    subnet_id      = each.value.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    for_each = aws_subnet.private

    subnet_id      = each.value.id
    route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "public_sg" {
    name        = local.public_sg_name
    description = "public_security_group"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 23
        to_port     = 23
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "private_sg" {
    name            = local.private_sg_name
    description     = "private_security_group"
    vpc_id          = aws_vpc.main.id

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "alb_sg" {
    name        = local.alb_sg_name
    description = "alb_security_group"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port  = 80
        to_port    = 80
        protocol   = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}