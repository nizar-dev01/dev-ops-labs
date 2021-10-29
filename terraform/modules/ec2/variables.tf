variable "instance_type" {
  type        = string
  description = "ec2 web server type"
  default     = "t2.micro"
}

variable "instance_ami" {
  type        = string
  description = "Server image to use"
  default     = "ami-085925f297f89fce1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "key_name" {
  type    = string
  default = "ec2_keys"
}

variable "private_subnet" {
  type = string
}
variable "public_subnet_one" {
  type = string
}
variable "public_subnet_two" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_env" {
  type = string
}
