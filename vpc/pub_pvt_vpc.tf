# Name: pub_pvt_vpc.tf
# Owner: Saurav Mitra
# Description: This terraform config will create a VPC with following resources:
#   1 Public Subnet
#   3 Private Subnets
#   1 Internet Gateway (with routes to it for Public Subnets).
#   1 NAT Gateway for outbound internet access (with routes from Private Subnets set to use it).
#   1 Elastic IP for NAT Gateway.
#   2 Routing tables (for Public and private subnet for routing the traffic).

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name  = "${var.prefix}-vpc"
    Owner = var.owner
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(values(var.public_subnets), count.index)
  availability_zone       = element(keys(var.public_subnets), count.index)
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.prefix}-public-subnet-${count.index}"
    Owner = var.owner
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(values(var.private_subnets), count.index)
  availability_zone = element(keys(var.private_subnets), count.index)

  tags = {
    Name  = "${var.prefix}-private-subnet-${count.index}"
    Owner = var.owner
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = "${var.prefix}-igw"
    Owner = var.owner
  }
}

# EIP
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name  = "${var.prefix}-nat-eip"
    Owner = var.owner
  }
}

# NAT
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.0.id

  tags = {
    Name  = "${var.prefix}-natgw"
    Owner = var.owner
  }

  # The NAT Gateway depends on the Elastic IP
  depends_on = [aws_internet_gateway.igw]
}

# Public RT
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "${var.prefix}-public-rt"
    Owner = var.owner
  }
}

# Public RT Association
resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnets)
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

# Private RT
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name  = "${var.prefix}-private-rt"
    Owner = var.owner
  }
}

# Private RT Association
resource "aws_route_table_association" "private_rta" {
  count          = length(var.private_subnets)
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}
