
variable "region" {}
variable "vpc_name" {}

variable "subnet_zones" {
  default = "a,b"
}

resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
      Name = "${var.vpc_name}"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id = "${aws_vpc.primary.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.region}${element(split(",", var.subnet_zones), 0)}"

  tags {
    Name = "Subnet ${element(split(",", var.subnet_zones), 0)}"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id = "${aws_vpc.primary.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.region}${element(split(",", var.subnet_zones), 1)}"

  tags {
    Name = "Subnet ${element(split(",", var.subnet_zones), 1)}"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${aws_vpc.primary.id}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}c"

  tags {
    Name = "Public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.primary.id}"

  tags {
    Name = "Main"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.primary.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "Main"
  }
}

resource "aws_route_table_association" "public_subnet_route_c" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.route_table.id}"
}

resource "aws_db_subnet_group" "rds_default" {
  name = "rds-default-production"
  description = "Available Subnets"
  subnet_ids = ["${aws_subnet.public_subnet_c.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_a.id}"]
}

resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name = "elasticache-subnet-group"
  description = "Redis Subnet"
  subnet_ids = ["${aws_subnet.public_subnet_c.id}"] #["${aws_subnet.public.id}"]
}

output "vpc_id" {
  value = "${aws_vpc.primary.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet_c.id}"
}

output "db_subnet_group" {
  value = "rds-default"
}

output "public_subnet_availability_zone" {
  value = "${var.region}c"
}

output "redis_subnet_group" { value = "elasticache-subnet-group" }
