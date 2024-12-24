variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "email_addresses" {
  description = "List of email addresses for notifications"
  type        = list(string)
}
