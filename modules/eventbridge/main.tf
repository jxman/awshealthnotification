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

  # Option 1: No transformation - send the raw event
  # This is the simplest and most reliable approach

  # Option 2: Use a minimal transformation that EventBridge can validate
  input_transformer {
    input_paths = {
      env         = "$.account"
      service     = "$.detail.service"
      status      = "$.detail.statusCode"
      eventType   = "$.detail.eventTypeCode"
      description = "$.detail.eventDescription[0].latestDescription"
      eventTime   = "$.time"
    }

    # This template creates valid JSON that EventBridge will accept
    input_template = <<EOF
{
  "default": "${upper(var.environment)} Health Alert: <service> - <status> - <eventType>\n\n<description>\n\nTime: <eventTime>"
}
EOF
  }
}
