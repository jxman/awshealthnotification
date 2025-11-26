output "rule_arn" {
  description = "ARN of the EventBridge rule that captures AWS Health Events. Use this ARN for cross-account event bus permissions or CloudWatch monitoring."
  value       = aws_cloudwatch_event_rule.health_events.arn
}

output "rule_name" {
  description = "Name of the EventBridge rule. Use this name to reference the rule in AWS Console or CLI commands for enabling/disabling or viewing event metrics."
  value       = aws_cloudwatch_event_rule.health_events.name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function that formats health event notifications. Use this to invoke the function directly for testing or add additional triggers."
  value       = aws_lambda_function.health_formatter.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function. Use this to view logs in CloudWatch Logs (/aws/lambda/<name>) or update function configuration."
  value       = aws_lambda_function.health_formatter.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function. Reference this if you need to add additional permissions for the Lambda function."
  value       = aws_iam_role.lambda_role.arn
}
