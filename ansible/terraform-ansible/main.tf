provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# create aws vpc
resource "aws_vpc" "tr-as-vpc" {
  cidr_block = "10.0.0.0/16"
}

# create a subnet in the vpc
resource "aws_subnet" "test" {
  vpc_id                  = aws_vpc.tr-as-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# create an internet gateway
resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.tr-as-vpc.id
}

# Create a route table for the subnet
resource "aws_route_table" "test" {
  vpc_id = aws_vpc.tr-as-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test.id
  }
}

# Create a route table association
resource "aws_route_table_association" "test" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.test.id
}

resource "aws_security_group" "web_access" {
  name        = "web-access-group"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.tr-as-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # allow ssh traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all outgoing traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "web-access-group"
  }
}

locals {
  ssh_user = "ubuntu"
  key_name = "ec2_keys"
  key_path = "~/Downloads/ec2_keys.pem"
}

resource "aws_instance" "public_instance" {
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = aws_subnet.test.id
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.web_access.id]
  associate_public_ip_address = true
  depends_on = [
    aws_security_group.web_access
  ]

  tags = {
    Name = "public-instance"
  }

  # attach a key pair
  key_name = "ec2_keys"

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.key_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i ${self.public_ip}, --private-key ${local.key_path} jenkins-play.yml"
  }

}

output "instance-public-ip" {
  value = aws_instance.public_instance.public_ip
}
