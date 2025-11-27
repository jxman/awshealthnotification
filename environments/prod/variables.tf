variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
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

variable "tags" {
  description = "Additional tags to apply to all resources (merged with common_tags in main.tf)"
  type        = map(string)
  default     = {}
}
