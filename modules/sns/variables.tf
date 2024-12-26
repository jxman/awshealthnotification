variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "email_addresses" {
  description = "List of email addresses for notifications"
  type        = list(string)
  default     = []
}

variable "phone_numbers" {
  description = "List of phone numbers for SMS notifications (E.164 format)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
