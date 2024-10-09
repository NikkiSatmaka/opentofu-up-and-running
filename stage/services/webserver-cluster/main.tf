terraform {
  required_version = "~>1.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.50"
    }
  }
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  profile = "cloudguru"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_launch_template" "example" {
  image_id = "ami-0866a3c8686eaeeba"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(
    <<-EOF
      #!/usr/bin/env bash
      echo "Hello, World" > index.html
      nohup busybox httpd -f -p ${var.server_port} &
    EOF
  )

  # Required when using a launch configuration with an auto scaling group
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id = aws_launch_template.example.id
  }
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "opentofu-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "opentofu-example-instance"
}

resource "aws_vpc_security_group_ingress_rule" "allow_webserver_ipv4" {
  security_group_id = aws_security_group.instance.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port = var.server_port
  ip_protocol = "tcp"
  to_port = var.server_port
}

resource "aws_security_group" "alb" {
  name = "opentofu-example-alb"
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_lb" "example" {
  name = "opentofu-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name = "opentofu-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
