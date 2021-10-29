# Create a VPC.
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    "Name" = "app-vpc-${var.app_env}"
  }
}

# Create public subnet-1.
resource "aws_subnet" "public-sub-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "public-subnet-1-${var.app_env}"
  }
}

# Create public subnet-2.
resource "aws_subnet" "public-sub-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-subnet-2-${var.app_env}"
  }
}

# Create an internet gateway.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "igw-${var.app_env}"
  }
}

# Create a public route table.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "pub-route-table-${var.app_env}"
  }
}

# Associate public subnets with the route table.
resource "aws_route_table_association" "public-1" {
  subnet_id      = aws_subnet.public-sub-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-2" {
  subnet_id      = aws_subnet.public-sub-2.id
  route_table_id = aws_route_table.public.id
}

# Create an Elastic IP
resource "aws_eip" "nat-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    "Name" = "eip-${var.app_env}"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-sub-1.id
  tags = {
    Name = "nat-${var.app_env}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create a private subnet.
resource "aws_subnet" "private-sub" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "private-subnet-${var.app_env}"
  }
}

# Create a route table for private-sub
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    "Name" = "pub-route-table-${var.app_env}"
  }
}

# Associate the route table with private-sub
resource "aws_route_table_association" "private-1" {
  subnet_id      = aws_subnet.private-sub.id
  route_table_id = aws_route_table.private.id
}
