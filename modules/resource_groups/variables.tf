variable "environment" {
  description = "Environment name (dev, staging, prod). Used for resource group naming and tag-based filtering. Groups all resources belonging to this environment's health notification infrastructure."
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  description = "Additional resource tags to apply to the resource group itself. Note: The resource group filters resources based on Environment, Service, and ManagedBy tags."
  type        = map(string)
  default     = {}
}
