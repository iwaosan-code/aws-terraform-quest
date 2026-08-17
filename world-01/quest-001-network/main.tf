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