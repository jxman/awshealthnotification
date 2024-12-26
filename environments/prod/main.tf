terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"

  backend "s3" {
    # Backend configuration will be provided via backend config file
    key = "health-notifications/prod/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

module "sns" {
  source = "../../modules/sns"

  environment     = var.environment
  email_addresses = var.email_addresses
  # phone_numbers   = var.phone_numbers
  tags = var.tags
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn
  tags          = var.tags
}
