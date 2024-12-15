# Email list variable with validation
variable "email_addresses" {
  description = "List of email addresses to receive notifications"
  type        = list(string)

  validation {
    condition     = length(var.email_addresses) > 0
    error_message = "At least one email address must be provided."
  }

  validation {
    condition     = alltrue([for email in var.email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "All email addresses must be in a valid format."
  }
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
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
