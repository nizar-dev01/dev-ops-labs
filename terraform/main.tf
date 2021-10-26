provider "aws" {
  region = "us-east-1"
}

# Create a VPC.
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    "Name" = "main"
  }
}

# Create public subnet-1.
resource "aws_subnet" "public-sub-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "public subnet 1"
  }
}

# Create public subnet-2.
resource "aws_subnet" "public-sub-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public subnet 2"
  }
}

# Create an internet gateway.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "Main IGW"
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
    "Name" = "Public Route Table"
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

#Create a Security Group for granding network access
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  # HTTPS
  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTP
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # SSH
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "LB Security Group"
  }
}

# Create an Elastic IP
resource "aws_eip" "nat-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    "Name" = "NAT Gateway EIP"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-sub-1.id
  tags = {
    Name = "gw NAT"
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
    "Name" = "private subnet"
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
    "Name" = "Public Route Table"
  }
}

# Associate the route table with private-sub
resource "aws_route_table_association" "private-1" {
  subnet_id      = aws_subnet.private-sub.id
  route_table_id = aws_route_table.private.id
}

# Create Ubuntu server and configure nginx
resource "aws_instance" "application-server-1" {
  ami               = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ec2_keys"
  subnet_id         = aws_subnet.private-sub.id
  security_groups = [
    aws_security_group.lb_sg.id
  ]

  depends_on = [
    aws_lb.load-balancer,
    aws_nat_gateway.nat
  ]

  user_data = <<-EOF
                V
                EOF
  tags = {
    Name = "web-server-1"
  }
}
resource "aws_instance" "application-server-2" {
  ami               = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ec2_keys"
  subnet_id         = aws_subnet.private-sub.id
  security_groups = [
    aws_security_group.lb_sg.id
  ]

  depends_on = [
    aws_lb.load-balancer,
    aws_nat_gateway.nat
  ]

  user_data = <<-EOF
                #!/bin/bash
                apt-get update && apt-get install build-essential git python3 python3-pip python3-venv nginx -y && pip3 install uwsgi
                python3 -m venv ~/app && source ~/app/bin/activate
                pip3 install django
                git clone https://github.com/nizar-dev01/baby-django.git ~/baby-django
                sed -i 's/***-lb-dns-***/${aws_lb.load-balancer.dns_name}/g' ~/baby-django/server.conf
                cp ~/baby-django/server.conf /etc/nginx/sites-available
                ln -s /etc/nginx/sites-available/server.conf /etc/nginx/sites-enabled

                sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf
                service nginx restart
                uwsgi --ini ~/baby-django/app_uwsgi.ini

                mkdir ~/app/vassals
                
                cp ~/baby-django/emperor.uwsgi.service /etc/systemd/system

                systemctl enable emperor.uwsgi.service
                systemctl start emperor.uwsgi.service
                EOF
  tags = {
    Name = "web-server-2"
  }
}

resource "aws_instance" "public-proxy-server" {
  ami               = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ec2_keys"
  subnet_id         = aws_subnet.public-sub-1.id
  security_groups = [
    aws_security_group.lb_sg.id
  ]

  depends_on = [
    aws_lb.load-balancer
  ]

  user_data = <<-EOF
                #!/bin/bash
                apt-get update &&  apt-get install build-essential git python3 python3-pip python3-venv nginx -y && pip3 install uwsgi
                python3 -m venv ~/app && source ~/app/bin/activate
                pip3 install django
                git clone https://github.com/nizar-dev01/baby-django.git ~/baby-django
                sed -i 's/***-lb-dns-***/${aws_lb.load-balancer.dns_name}/g' /etc/nginx/nginx.conf
                cp ~/baby-django/server.conf /etc/nginx/sites-available
                ln -s /etc/nginx/sites-available/server.conf /etc/nginx/sites-enabled

                sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf
                service nginx restart
                uwsgi --ini ~/baby-django/app_uwsgi.ini

                mkdir ~/app/vassals
                
                cp ~/baby-django/emperor.uwsgi.service /etc/systemd/system

                systemctl enable emperor.uwsgi.service
                systemctl start emperor.uwsgi.service
                EOF
  tags = {
    Name = "proxy-server"
  }
}

# Set up a Load Balancer
resource "aws_lb" "load-balancer" {
  name               = "app-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets = [
    aws_subnet.public-sub-1.id,
    aws_subnet.public-sub-2.id
  ]

  enable_cross_zone_load_balancing = false

  tags = {
    Name = "Application Load Balancer"
  }
}

# Create a Target Group
resource "aws_lb_target_group" "target-group" {
  name     = "tg-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled = true
  }

  tags = {
    "Name" = "App Target Group"
  }
}

# Attach the instances with the target group
resource "aws_lb_target_group_attachment" "attach-1" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.application-server-1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "attach-2" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.application-server-2.id
  port             = 80
}

# Create a listener for the load balancer
resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

# Print important data
output "server-1-id" {
  value = aws_instance.application-server-1.id
}
output "server-2-id" {
  value = aws_instance.application-server-2.id
}
output "load-balancer-dns" {
  value = aws_lb.load-balancer.dns_name
}
