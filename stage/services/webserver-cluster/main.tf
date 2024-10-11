terraform {
  required_version = "~>1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.60"
    }
  }
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "cloudguru"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "opentofu-up-and-running-state-548315"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}

resource "aws_vpc_security_group_ingress_rule" "allow_testing_inbound" {
  security_group_id = module.webserver_cluster.alb_security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 12345
  ip_protocol       = "tcp"
  to_port           = 12345
}
