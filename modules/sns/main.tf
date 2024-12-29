# Purpose: Create an SNS topic and subscriptions for AWS Health events

# SNS Topic for Health Events
resource "aws_sns_topic" "health_events" {
  name         = "${var.environment}-health-event-notifications"
  display_name = "AWS Health Events - ${var.environment}"
  tags         = var.tags
}

# Email Subscriptions
resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each  = toset(var.email_addresses)
  topic_arn = aws_sns_topic.health_events.arn
  protocol  = "email"
  endpoint  = each.value
}

# SMS Subscriptions
resource "aws_sns_topic_subscription" "sms_subscriptions" {
  for_each  = toset(var.phone_numbers)
  topic_arn = aws_sns_topic.health_events.arn
  protocol  = "sms"
  endpoint  = each.value
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.health_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.health_events.arn
      }
    ]
  })
}
