resource "aws_resourcegroups_group" "health_notifications" {
  name = "${var.environment}-health-notifications"

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
      Name = "${var.environment}-health-notifications-resource-group"
    }
  )
}
