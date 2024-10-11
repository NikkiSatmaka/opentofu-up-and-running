terraform {
  required_version = "~>1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.60"
    }
  }
  backend "s3" {
    key = "prod/services/webserver-cluster/terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "cloudguru"
}

module "webserver_cluster" {
  source = "github.com/NikkiSatmaka/opentofu-up-and-running-modules//services/webserver-cluster?ref=v0.0.1"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "opentofu-up-and-running-state-462468"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "m5.large"
  min_size      = 2
  max_size      = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hour" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}
