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
  "Environment": "${var.environment}",
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
  "Description": "<eventDescription>"
}
EOF
  }
}
