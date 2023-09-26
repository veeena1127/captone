terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 0.12"
}


resource "aws_vpc" "UpgradVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "UpgradVPC"
           }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.UpgradVPC.id
  count                   = length(var.subnets_count)
  availability_zone       = element(var.availability_zone, count.index)
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-sub-${element(var.availability_zone, count.index)}"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.UpgradVPC.id
  count             = length(var.subnets_count)
  availability_zone = element(var.availability_zone, count.index)
  cidr_block        = "10.0.${count.index + 2}.0/24"

  tags = {
    Name = "pri-sub-${element(var.availability_zone, count.index)}"
  }
}


#Internet gateway
resource "aws_internet_gateway" "veena-igw" {
  vpc_id = aws_vpc.UpgradVPC.id
  tags = {
    "Name"        = "veena-igw"
  }
}

# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.veena-igw]
}


#  NAT Gateway
resource "aws_nat_gateway" "nat-gateway-veena" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  tags = {
    Name        = "nat-gateway-veena"
  }
}

# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.UpgradVPC.id
  tags = {
    Name        = "Upgrad-private-route-table"
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.UpgradVPC.id
  tags = {
    Name        = "Upgrad-public-route-table"
  }
}


# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.veena-igw.id
}

# Route for NAT Gateway
resource "aws_route" "private_internet_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gateway-veena.id
}

# Route table associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.subnets_count)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}


# Route table associations for Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(var.subnets_count)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
