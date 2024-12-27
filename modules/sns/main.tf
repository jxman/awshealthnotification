resource "aws_sns_topic" "health_events" {
  name         = "${var.environment}-health-event-notifications"
  display_name = "AWS Health Events - ${var.environment}"
  tags         = var.tags
}

# Email Subscriptions
resource "aws_sns_topic_subscription" "email_subscriptions" {
  count     = length(var.email_addresses)
  topic_arn = aws_sns_topic.health_events.arn
  protocol  = "email"
  endpoint  = var.email_addresses[count.index]

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [aws_sns_topic.health_events.arn]
  }
}

# SMS Subscriptions
resource "aws_sns_topic_subscription" "sms_subscriptions" {
  count     = length(var.phone_numbers)
  topic_arn = aws_sns_topic.health_events.arn
  protocol  = "sms"
  endpoint  = var.phone_numbers[count.index]

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [aws_sns_topic.health_events.arn]
  }
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
