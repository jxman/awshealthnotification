variable "environment" {
  description = "Environment name (dev, staging, prod). Used for SNS topic naming and tagging. Creates isolated notification topics per environment."
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  description = "Additional resource tags to apply to SNS topic and related resources. These tags are merged with default tags (Environment, Service, ManagedBy, SubService)."
  type        = map(string)
  default     = {}
}
