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
    tags = {
      Environment       = var.environment
      ManagedBy         = "terraform"
      TerraformWorkflow = "github-actions"
      Project           = "aws-health-notifications"
    }
  }
}

# Define common tags
locals {
  common_tags = {
    Environment       = var.environment
    Service           = "aws-health-notifications"
    ManagedBy         = "terraform"
    TerraformRepo     = "github.com/${var.github_org}/${var.github_repo}"
    TerraformWorkflow = "github-actions"
    Owner             = var.owner_team
    CostCenter        = var.cost_center
    Project           = "health-monitoring"
    CreatedBy         = "terraform-aws-health-notification"
  }

  # Merge common tags with any resource-specific tags
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
