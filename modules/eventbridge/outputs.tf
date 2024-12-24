output "rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.health_events.arn
}

output "rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.health_events.name
}
