resource "aws_cloudwatch_event_rule" "health_events" {
  name        = "${var.environment}-health-event-notifications"
  description = "Captures AWS Health Events for ${var.environment}"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.health_events.name
  target_id = "HealthNotificationTarget"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      service     = "$.detail.service"
      status      = "$.detail.statusCode"
      eventType   = "$.detail.eventTypeCode"
      category    = "$.detail.eventTypeCategory"
      description = "$.detail.eventDescription[0].latestDescription"
      eventArn    = "$.detail.eventArn"
      startTime   = "$.detail.startTime"
      endTime     = "$.detail.endTime"
      eventTime   = "$.time"
      region      = "$.region"
      account     = "$.account"
    }

    # Enhanced formatting that EventBridge should accept
    input_template = <<EOF
{
  "default": "🔔 AWS Health Event - ${upper(var.environment)} Environment\n----------------------------------------\n\n📊 Event Summary:\n• Service: <service>\n• Status: <status>\n• Type: <eventType>\n• Category: <category>\n\n🕒 Timeline:\n• Detected: <eventTime>\n• Started: <startTime>\n• Ended: <endTime>\n\n📝 Description:\n<description>\n\n🔍 Details:\n• Event ARN: <eventArn>\n• Region: <region>\n• Account: <account>\n\n----------------------------------------\nAWS Health Event Monitoring System"
}
EOF
  }
}
