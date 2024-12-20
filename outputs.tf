output "sns_topic_arn" {
  description = "ARN of the SNS Topic"
  value       = aws_sns_topic.health_events.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge Rule"
  value       = aws_cloudwatch_event_rule.health_events.arn
}
