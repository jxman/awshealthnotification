/**
 * # SNS Topic Module for Health Notifications
 *
 * This module creates and configures an SNS topic for distributing AWS Health Event
 * notifications to subscribers (email, SMS, Lambda, etc.).
 *
 * ## Features
 *
 * - **SNS Topic**: Central notification distribution point for health events
 * - **Encryption**: AWS-managed KMS encryption at rest
 * - **EventBridge Integration**: Topic policy allows EventBridge to publish messages
 * - **Multi-Subscriber Support**: Can notify multiple endpoints (email, SMS, Lambda, SQS, etc.)
 * - **Environment Isolation**: Separate topics per environment (dev, prod)
 *
 * ## Security
 *
 * - Encrypted at rest using AWS-managed KMS key (alias/aws/sns)
 * - Least-privilege topic policy (only EventBridge can publish)
 * - No public access - subscribers must be explicitly added
 *
 * ## Usage Notes
 *
 * Subscribers must be added separately after topic creation:
 * - Email subscriptions require confirmation
 * - SMS subscriptions require phone number in E.164 format
 * - Lambda subscriptions require appropriate IAM permissions
 */

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
