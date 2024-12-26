variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "email_addresses" {
  description = "List of email addresses for notifications"
  type        = list(string)
}

variable "phone_numbers" {
  description = "List of phone numbers for SMS notifications"
  type        = list(string)
  default     = []
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
  description = "Resource tags"
  type        = map(string)
  default = {
    Environment = "dev"
    Service     = "aws-health-notifications"
    ManagedBy   = "terraform"
  }
}
