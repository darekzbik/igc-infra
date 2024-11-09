resource "aws_vpc" "vpc" {
  cidr_block           = "172.21.0.0/20"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"

  tags = {
    Name = "igc"
  }
}

resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.21.1.0/24"
  tags       = {
    Name = "igc-sub1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "igc" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "igc"
  }
}

resource "aws_route_table_association" "igc-sub1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.igc.id
}
