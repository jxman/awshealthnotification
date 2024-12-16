# Provider configuration
provider "aws" {
  region = var.aws_region
}

# SNS Topic
resource "aws_sns_topic" "health_events" {
  name         = "health-event-notifications"
  display_name = "AWS Health Events"
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

# Email Subscriptions
resource "aws_sns_topic_subscription" "email_subscriptions" {
  count     = length(var.email_addresses)
  topic_arn = aws_sns_topic.health_events.arn
  protocol  = "email"
  endpoint  = var.email_addresses[count.index]

  lifecycle {
    ignore_changes = [
      # Ignore changes to subscription status as it's managed outside Terraform
      pending_confirmation
    ]
  }
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "health_events" {
  name        = "health-event-notifications"
  description = "Captures AWS Health Events and sends notifications"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.health_events.name
  target_id = "HealthNotificationTarget"
  arn       = aws_sns_topic.health_events.arn

  input_transformer {
    input_paths = {
      eventSource       = "$.source"
      eventType         = "$.detail-type"
      eventTime         = "$.time"
      region            = "$.region"
      account           = "$.account"
      healthService     = "$.detail.service"
      eventDescription  = "$.detail.eventDescription[0].latestDescription"
      eventTypeCode     = "$.detail.eventTypeCode"
      eventTypeCategory = "$.detail.eventTypeCategory"
      statusCode        = "$.detail.statusCode"
      startTime         = "$.detail.startTime"
      endTime           = "$.detail.endTime"
      eventArn          = "$.detail.eventArn"
    }

    input_template = <<EOF
{
  "Event Source": "<eventSource>",
  "Event Type": "<eventType>",
  "Event ARN": "<eventArn>",
  "Time Detected": "<eventTime>",
  "Start Time": "<startTime>",
  "End Time": "<endTime>",
  "Region": "<region>",
  "Account": "<account>",
  "Service Affected": "<healthService>",
  "Event Type Code": "<eventTypeCode>",
  "Category": "<eventTypeCategory>",
  "Status": "<statusCode>",
  "Description": "<eventDescription>",
  "Summary": "[<statusCode>] AWS Health Event detected for <healthService> in <region>. Event type: <eventTypeCode>. Description: <eventDescription>"
}
EOF
  }
}
