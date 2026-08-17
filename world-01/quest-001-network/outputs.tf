output vpc_id {
    value = aws_vpc.main.id
}

output public_subnet_ids {
    value = {for k, s in aws_subnet.public : k => s.id}
}

output private_subnet_ids {
    value = {for k, s in aws_subnet.private : k => s.id}
}

output igw_id {
    value = aws_internet_gateway.igw.id
}