variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "email_addresses" {
  description = "List of email addresses to receive notifications"
  type        = list(string)
}

# Backend configuration variables
variable "terraform_state_bucket" {
  description = "S3 bucket for storing terraform state"
  type        = string
}

variable "terraform_state_key" {
  description = "S3 key for terraform state"
  type        = string
  default     = "health-notifications/terraform.tfstate"
}

variable "terraform_state_dynamodb_table" {
  description = "DynamoDB table for terraform state locking"
  type        = string
}
