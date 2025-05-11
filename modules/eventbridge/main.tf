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

  # Very basic input transformer that EventBridge accepts
  input_transformer {
    input_paths = {
      service     = "$.detail.service"
      status      = "$.detail.statusCode"
      eventType   = "$.detail.eventTypeCode"
      description = "$.detail.eventDescription[0].latestDescription"
      region      = "$.region"
      time        = "$.time"
    }

    # Simple template that works reliably with EventBridge
    input_template = "${upper(var.environment)} Health Alert: <service> (<status>)\n\n<description>\n\nRegion: <region>\nTime: <time>"
  }
}
