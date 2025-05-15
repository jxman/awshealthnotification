resource "aws_sns_topic" "health_events" {
  name         = "${var.environment}-health-event-notifications"
  display_name = "AWS Health Events - ${var.environment}"

  tags = merge(
    local.resource_tags,
    {
      Name    = "${var.environment}-health-event-notifications"
      Service = "notifications"
    }
  )
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
