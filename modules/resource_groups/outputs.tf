output "group_arn" {
  description = "ARN of the resource group containing all health notification infrastructure. Use this ARN to apply group-level CloudWatch dashboards, cost allocation tags, or IAM policies."
  value       = aws_resourcegroups_group.health_notifications.arn
}

output "group_name" {
  description = "Name of the resource group. Use this name to view grouped resources in AWS Console Resource Groups & Tag Editor or generate compliance reports."
  value       = aws_resourcegroups_group.health_notifications.name
}
