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

    input_template = <<-EOF
"AWS Health Event Notification - ${upper(var.environment)} Environment

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔔 NOTIFICATION SUMMARY

Environment: ${upper(var.environment)}
Service Affected: <healthService>
Status: <statusCode>
Event Type: <eventTypeCode>
Category: <eventTypeCategory>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 EVENT TIMELINE

Time Detected: <eventTime>
Start Time: <startTime>
End Time: <endTime>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 EVENT DETAILS

Event ARN: <eventArn>
Region: <region>
Account: <account>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 EVENT DESCRIPTION

<eventDescription>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️ SOURCE INFORMATION

Event Source: <eventSource>
Event Type: <eventType>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is an automated notification from AWS Health Event Monitoring System.
For more information, please check your AWS Personal Health Dashboard."
EOF
  }
}
