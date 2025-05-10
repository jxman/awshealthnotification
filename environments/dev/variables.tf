variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for storing terraform state"
  type        = string
}

variable "terraform_state_key" {
  description = "S3 key for terraform state"
  type        = string
}

variable "terraform_state_dynamodb_table" {
  description = "DynamoDB table for terraform state locking"
  type        = string
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Service     = "aws-health-notifications"
  }
}
