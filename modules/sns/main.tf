# Define local variables for tags
locals {
  resource_tags = merge(
    {
      Name        = "${var.environment}-health-event-notifications"
      Environment = var.environment
      Service     = "aws-health-notifications"
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_sns_topic" "health_events" {
  name         = "${var.environment}-health-event-notifications"
  display_name = "AWS Health Events - ${var.environment}"

  # Enable encryption with AWS managed key
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.resource_tags,
    {
      Name       = "${var.environment}-health-event-notifications"
      SubService = "health-notifications-topic"
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
