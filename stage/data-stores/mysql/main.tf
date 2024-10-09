terraform {
  required_version = "~>1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.60"
    }
  }
  backend "s3" {
    key = "stage/data-stores/mysql/terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "cloudguru"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "opentofu-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "example_database"

  username = var.db_username
  password = var.db_password
}
