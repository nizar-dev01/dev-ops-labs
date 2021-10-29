# Create a template file from the shell script to run as user_data
data "template_file" "user_data" {
  template = file("modules/ec2/init.sh")
}
# Create Ubuntu server and configure nginx
resource "aws_instance" "application-server-1" {
  ami               = var.instance_ami
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = var.key_name
  subnet_id         = var.private_subnet
  security_groups = [
    var.app_security_group_id
  ]

  depends_on = [
    aws_lb.load-balancer
  ]

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "web-server-1-${var.app_env}"
  }
}
resource "aws_instance" "application-server-2" {
  ami               = var.instance_ami
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = var.key_name
  subnet_id         = var.private_subnet
  security_groups   = [var.app_security_group_id]

  depends_on = [
    aws_lb.load-balancer
  ]

  user_data = data.template_file.user_data.rendered
  tags = {
    Name = "web-server-2-${var.app_env}"
  }
}

resource "aws_instance" "public-proxy-server" {
  count             = var.app_env == "production" ? 0 : 1
  ami               = var.instance_ami
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = var.key_name
  subnet_id         = var.public_subnet_one
  security_groups   = [var.app_security_group_id]

  tags = {
    Name = "proxy-server-${var.app_env}"
  }
}

# Set up a Load Balancer
resource "aws_lb" "load-balancer" {
  name               = "app-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.app_security_group_id]
  subnets = [
    var.public_subnet_one,
    var.public_subnet_two
  ]

  enable_cross_zone_load_balancing = false

  tags = {
    Name = "load-balancer-${var.app_env}"
  }
}

# Create a Target Group
resource "aws_lb_target_group" "target-group" {
  name     = "tg-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled = true
  }

  tags = {
    "Name" = "target-group-${var.app_env}"
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
