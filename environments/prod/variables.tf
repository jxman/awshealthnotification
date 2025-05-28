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
