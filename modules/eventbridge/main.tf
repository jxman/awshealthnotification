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
  "default": "AWS Health Event Notification - ${upper(var.environment)} Environment\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n🔔 NOTIFICATION SUMMARY\n\nEnvironment: ${upper(var.environment)}\nService Affected: <healthService>\nStatus: <statusCode>\nEvent Type: <eventTypeCode>\nCategory: <eventTypeCategory>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n📅 EVENT TIMELINE\n\nTime Detected: <eventTime>\nStart Time: <startTime>\nEnd Time: <endTime>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n📌 EVENT DETAILS\n\nEvent ARN: <eventArn>\nRegion: <region>\nAccount: <account>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n📝 EVENT DESCRIPTION\n\n<eventDescription>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n⚙️ SOURCE INFORMATION\n\nEvent Source: <eventSource>\nEvent Type: <eventType>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\nThis is an automated notification from AWS Health Event Monitoring System.\nFor more information, please check your AWS Personal Health Dashboard.",
  "sms": "[${upper(var.environment)}] AWS Health: <healthService> <statusCode> - <eventTypeCode>. Check email for details.",
  "email": "AWS Health Event Notification - ${upper(var.environment)} Environment\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n🔔 NOTIFICATION SUMMARY\n\nEnvironment: ${upper(var.environment)}\nService Affected: <healthService>\nStatus: <statusCode>\nEvent Type: <eventTypeCode>\nCategory: <eventTypeCategory>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n📅 EVENT TIMELINE\n\nTime Detected: <eventTime>\nStart Time: <startTime>\nEnd Time: <endTime>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n📌 EVENT DETAILS\n\nEvent ARN: <eventArn>\nRegion: <region>\nAccount: <account>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n📝 EVENT DESCRIPTION\n\n<eventDescription>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n⚙️ SOURCE INFORMATION\n\nEvent Source: <eventSource>\nEvent Type: <eventType>\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\nThis is an automated notification from AWS Health Event Monitoring System.\nFor more information, please check your AWS Personal Health Dashboard."
}
EOF
  }
}
