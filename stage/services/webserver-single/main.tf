terraform {
  required_version = "~>1.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.50"
    }
    http = {
      source = "hashicorp/http"
      version = "~>3.2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  profile = "cloudguru"
}

provider "http" {}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_region" "current" {}

data "aws_ec2_managed_prefix_list" "instance_connect" {
  name = "com.amazonaws.${data.aws_region.current.name}.ec2-instance-connect"
}

resource "aws_instance" "example" {
  ami = "ami-0866a3c8686eaeeba"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/usr/bin/env bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "opentofu-example"
  }
}

resource "aws_security_group" "instance" {
  name = "opentofu-example-instance"
}

resource "aws_vpc_security_group_ingress_rule" "allow_webserver_ipv4" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = var.server_port
  ip_protocol = "tcp"
  to_port = var.server_port
}

resource "aws_vpc_security_group_ingress_rule" "allow_instance_connect_ipv4" {
  security_group_id = aws_security_group.instance.id
  prefix_list_id = data.aws_ec2_managed_prefix_list.instance_connect.id
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4 = "${chomp(data.http.myip.response_body)}/32"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}
