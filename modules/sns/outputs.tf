output "topic_arn" {
  description = "ARN of the SNS topic for health event notifications. Use this ARN to create subscriptions (email, SMS, Lambda, SQS) or grant publish permissions to other services."
  value       = aws_sns_topic.health_events.arn
}

output "topic_name" {
  description = "Name of the SNS topic. Use this name to reference the topic in AWS Console or CLI commands for managing subscriptions and viewing metrics."
  value       = aws_sns_topic.health_events.name
}

output "topic_id" {
  description = "ID of the SNS topic (same as ARN). Provided for compatibility with modules that expect an ID output."
  value       = aws_sns_topic.health_events.id
}
