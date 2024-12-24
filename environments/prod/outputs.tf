output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.sns.topic_arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = module.eventbridge.rule_arn
}
