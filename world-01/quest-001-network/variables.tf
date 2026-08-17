variable region_name {
    type = string
}

variable vpc_cidr {
    type = string
}

variable public_subnets {
    type = map(string)
}

variable private_subnets {
    type = map(string)
}

variable availability_zones {
    type = list(string)
}

variable instance_type {
    type = string
}

variable tags {
    type  = map(string)
}