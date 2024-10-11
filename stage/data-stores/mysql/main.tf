terraform {
  required_version = "~>1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.60"
    }
  }
  backend "s3" {
    profile        = "cloudguru"
    bucket         = "opentofu-up-and-running-state-548315"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "opentofu-up-and-running-locks"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "cloudguru"
}

module "database" {
  source               = "../../../modules/data-stores/mysql"
  db_username          = var.db_password
  db_password          = var.db_password
  db_identifier_prefix = "opentofu-up-and-running-stage-"
  db_name              = "example"
  db_instance_class    = "db.t3.micro"
  allocated_storage    = 10
}
