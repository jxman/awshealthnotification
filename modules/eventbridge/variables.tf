variable "environment" {
  description = "Environment name (dev, staging, prod). Used for resource naming and tagging. Determines which environment's health events are captured."
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic where formatted health event notifications will be published. Lambda function will publish to this topic after formatting the event."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sns:[a-z0-9-]+:[0-9]{12}:.+$", var.sns_topic_arn))
    error_message = "SNS topic ARN must be a valid ARN format."
  }
}

variable "tags" {
  description = "Additional resource tags to apply to all resources created by this module. These tags are merged with default tags (Environment, Service, ManagedBy)."
  type        = map(string)
  default     = {}
}

variable "enabled" {
  description = "Enable or disable the EventBridge rule. When false, the rule exists but is in DISABLED state, preventing event processing without resource destruction. Useful for temporarily disabling notifications in non-prod environments."
  type        = bool
  default     = true
}
