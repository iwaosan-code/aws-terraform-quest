output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = { for k, s in aws_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  value = { for k, s in aws_subnet.private : k => s.id }
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "public_sg_id" {
  value = aws_security_group.public_sg.id
}

output "private_sg_id" {
  value = aws_security_group.private_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "instance_ids" {
    value = aws_instance.ec2_private.id
}

output "private_ips" {
    value = aws_instance.ec2_private.private_ip
}

output "alb_dns_name" {
    value = aws_alb.main.dns_name
}