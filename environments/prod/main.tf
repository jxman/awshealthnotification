provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}
module "sns" {
  source = "../../modules/sns"

  environment     = var.environment
  email_addresses = var.email_addresses
  tags            = var.tags
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn
  tags          = var.tags
}
