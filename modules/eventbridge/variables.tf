variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}
