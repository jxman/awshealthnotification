terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"

  backend "s3" {} # Empty block to be configured via backend.hcl
}

provider "aws" {
  region = var.aws_region
}

module "sns" {
  source = "../../modules/sns"

  environment = var.environment
  tags        = var.tags
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn
  tags          = var.tags
}
