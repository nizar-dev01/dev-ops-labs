output "private_subnet" {
  value = aws_subnet.private-sub.id
}

output "public_subnet_one" {
  value = aws_subnet.public-sub-1.id
}

output "public_subnet_two" {
  value = aws_subnet.public-sub-2.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

