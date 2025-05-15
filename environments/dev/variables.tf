variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev" # Change to "prod" for production environment
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

variable "github_org" {
  description = "GitHub organization name for the repository"
  type        = string
  default     = "xman" # Replace with your actual GitHub org name
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "aws-health-notifications" # Replace with your actual repo name
}

variable "owner_team" {
  description = "Team responsible for these resources"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
  default     = "platform-engineering"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
