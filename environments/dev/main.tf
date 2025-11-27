# Paste content from 'env-main-with-tags' artifact
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

  default_tags {
    tags = local.common_tags
  }
}

# Define common tags
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "John Xanthopoulos"
    Project     = "aws-health-notifications"
    Service     = "aws-health-notifications"
    GithubRepo  = "github.com/${var.github_org}/${var.github_repo}"
    Site        = "N/A"
    BaseProject = "aws-health-notifications"
  }

  # Merge common tags with any additional tags from variable
  resource_tags = merge(local.common_tags, var.tags)
}

module "sns" {
  source = "../../modules/sns"

  environment = var.environment
  tags        = local.resource_tags
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn
  enabled       = false # Disable dev EventBridge - only enable when testing
  tags          = local.resource_tags
}

module "resource_groups" {
  source = "../../modules/resource_groups"

  environment = var.environment
  tags        = local.resource_tags
}
