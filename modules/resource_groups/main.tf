/**
 * # Resource Groups Module
 *
 * This module creates AWS Resource Groups to organize and manage all resources
 * associated with the AWS Health Notifications infrastructure.
 *
 * ## Features
 *
 * - **Tag-Based Grouping**: Automatically groups resources using tag filters
 * - **Multi-Resource Support**: Supports all AWS resource types
 * - **Environment Isolation**: Separate resource groups per environment
 * - **Compliance Tracking**: Simplifies auditing and compliance reporting
 * - **Cost Allocation**: Enables cost tracking by resource group
 *
 * ## Resource Query
 *
 * The resource group uses tag-based queries to automatically include resources with:
 * - `Environment = <environment>` (dev, prod, etc.)
 * - `Service = aws-health-notifications`
 * - `ManagedBy = terraform`
 *
 * ## Use Cases
 *
 * - **Operations**: View all related resources in AWS Console in one place
 * - **Monitoring**: Apply CloudWatch dashboards and alarms to entire group
 * - **Cost Management**: Track costs for the entire notification system
 * - **Compliance**: Generate compliance reports for grouped resources
 * - **Automation**: Perform bulk operations on all resources in the group
 */

resource "aws_resourcegroups_group" "health_notifications" {
  name        = "${var.environment}-health-notifications"
  description = "Resource group for AWS Health Notifications infrastructure in ${var.environment} environment"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Environment"
          Values = [var.environment]
        },
        {
          Key    = "Service"
          Values = ["aws-health-notifications"]
        },
        {
          Key    = "ManagedBy"
          Values = ["terraform"]
        }
      ]
    })
    type = "TAG_FILTERS_1_0"
  }

  tags = merge(
    var.tags,
    {
      Name       = "${var.environment}-health-notifications-resource-group"
      SubService = "resource-group"
    }
  )
}
