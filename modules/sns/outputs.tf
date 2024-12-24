output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.health_events.arn
}

output "topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.health_events.name
}
