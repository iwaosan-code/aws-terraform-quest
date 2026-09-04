output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}