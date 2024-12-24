variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "email_addresses" {
  description = "List of email addresses for notifications"
  type        = list(string)
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

# Update SNS resource in modules/sns/main.tf:
resource "aws_sns_topic" "health_events" {
  name         = "${var.environment}-health-event-notifications"
  display_name = "AWS Health Events - ${var.environment}"
  tags         = var.tags
}
