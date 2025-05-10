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
  "default": "<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; background-color: #f4f4f4; }
        .container { max-width: 800px; margin: 0 auto; background-color: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { background-color: #232F3E; color: white; padding: 15px; text-align: center; border-radius: 8px 8px 0 0; margin: -20px -20px 20px -20px; }
        .section { margin-bottom: 20px; padding: 15px; background-color: #f8f9fa; border-left: 4px solid #FF9900; }
        .section h3 { margin-top: 0; color: #232F3E; }
        .details { display: grid; grid-template-columns: 150px 1fr; gap: 10px; }
        .label { font-weight: bold; color: #555; }
        .value { color: #333; }
        .description { background-color: #fff; padding: 15px; border: 1px solid #ddd; border-radius: 4px; margin: 10px 0; }
        .status-open { color: #d13212; }
        .status-closed { color: #2ea043; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>AWS Health Event Notification</h1>
            <p>${upper(var.environment)} Environment</p>
        </div>
        
        <div class='section'>
            <h3>🔔 Event Summary</h3>
            <div class='details'>
                <div class='label'>Service Affected:</div>
                <div class='value'><strong><healthService></strong></div>
                <div class='label'>Status:</div>
                <div class='value'><span class='status-<statusCode>'><statusCode></span></div>
                <div class='label'>Event Type:</div>
                <div class='value'><eventTypeCode></div>
                <div class='label'>Category:</div>
                <div class='value'><eventTypeCategory></div>
            </div>
        </div>
        
        <div class='section'>
            <h3>📅 Timeline</h3>
            <div class='details'>
                <div class='label'>Detected:</div>
                <div class='value'><eventTime></div>
                <div class='label'>Started:</div>
                <div class='value'><startTime></div>
                <div class='label'>Ended:</div>
                <div class='value'><endTime></div>
            </div>
        </div>
        
        <div class='section'>
            <h3>📌 Event Details</h3>
            <div class='details'>
                <div class='label'>Event ARN:</div>
                <div class='value' style='word-break: break-all;'><eventArn></div>
                <div class='label'>Region:</div>
                <div class='value'><region></div>
                <div class='label'>Account:</div>
                <div class='value'><account></div>
            </div>
        </div>
        
        <div class='section'>
            <h3>📝 Description</h3>
            <div class='description'>
                <eventDescription>
            </div>
        </div>
        
        <div class='footer'>
            <p>This is an automated notification from AWS Health Event Monitoring System.</p>
            <p>For more information, please check your <a href='https://phd.aws.amazon.com/'>AWS Personal Health Dashboard</a>.</p>
        </div>
    </div>
</body>
</html>",
  "sms": "[${upper(var.environment)}] AWS Health: <healthService> <statusCode> - <eventTypeCode>. Check email for details."
}
EOF
  }
}
