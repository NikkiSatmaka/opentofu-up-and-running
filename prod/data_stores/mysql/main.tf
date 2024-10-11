terraform {
  required_version = "~>1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.60"
    }
  }
  backend "s3" {
    key = "prod/data-stores/mysql/terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "cloudguru"
}

module "database" {
  source               = "github.com/NikkiSatmaka/opentofu-up-and-running-modules//data-stores/mysql?ref=v0.0.1"
  db_username          = var.db_password
  db_password          = var.db_password
  db_identifier_prefix = "db-prod-"
  db_name              = "example"
  db_instance_class    = "db.m5.large"
  allocated_storage    = 20
}
