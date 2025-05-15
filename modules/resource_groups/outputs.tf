output "group_arn" {
  description = "ARN of the resource group"
  value       = aws_resourcegroups_group.health_notifications.arn
}

output "group_name" {
  description = "Name of the resource group"
  value       = aws_resourcegroups_group.health_notifications.name
}
