# Resource Groups Module

This module creates AWS Resource Groups to organize and manage all resources associated with the AWS Health Notifications infrastructure.

## Features

- **Tag-Based Grouping**: Automatically groups resources using tag filters
- **Multi-Resource Support**: Supports all AWS resource types
- **Environment Isolation**: Separate resource groups per environment
- **Compliance Tracking**: Simplifies auditing and compliance reporting
- **Cost Allocation**: Enables cost tracking by resource group

## Architecture

```
Resource Group (Tag Query)
  ├── EventBridge Rule
  ├── Lambda Function
  ├── IAM Roles & Policies
  ├── SNS Topic
  └── CloudWatch Log Groups
```

## Usage Example

### Basic Usage

```hcl
module "resource_group" {
  source = "../../modules/resource_groups"

  environment = "prod"

  tags = {
    Project    = "aws-health-notifications"
    Owner      = "platform-team"
    CostCenter = "infrastructure"
  }
}
```

### Complete Example with All Modules

```hcl
# Create resource group
module "resource_group" {
  source      = "../../modules/resource_groups"
  environment = "prod"
  tags        = local.common_tags
}

# Create SNS topic
module "sns" {
  source      = "../../modules/sns"
  environment = "prod"
  tags        = local.common_tags
}

# Create EventBridge rule with Lambda
module "eventbridge" {
  source        = "../../modules/eventbridge"
  environment   = "prod"
  sns_topic_arn = module.sns.topic_arn
  enabled       = true
  tags          = local.common_tags
}

# Common tags that will be used to group resources
locals {
  common_tags = {
    Environment = "prod"
    Service     = "aws-health-notifications"
    ManagedBy   = "terraform"
    Project     = "aws-health-notifications"
    Owner       = "platform-team"
  }
}
```

## Resource Query

The resource group uses tag-based queries to automatically include resources with:
- `Environment = <environment>` (dev, prod, etc.)
- `Service = aws-health-notifications`
- `ManagedBy = terraform`

Any resource created with these three tags will automatically appear in the resource group.

## Use Cases

### Operations Dashboard

View all related resources in one place:
1. Go to AWS Console → Resource Groups & Tag Editor
2. Select your resource group (e.g., `prod-health-notifications`)
3. View all resources at a glance

### Cost Tracking

Generate cost reports for the entire notification system:

```bash
# Get cost for resource group
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-02-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Service \
  --filter file://filter.json

# filter.json
{
  "Tags": {
    "Key": "Service",
    "Values": ["aws-health-notifications"]
  }
}
```

### Compliance Auditing

List all resources for compliance reporting:

```bash
# List all resources in group
aws resource-groups list-group-resources \
  --group-name prod-health-notifications \
  --output table

# Get detailed resource information
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Service,Values=aws-health-notifications \
  --query 'ResourceTagMappingList[*].[ResourceARN,Tags]' \
  --output table
```

### Bulk Operations

Apply changes to all resources in the group:

```bash
# Tag all resources with new compliance tag
aws resourcegroupstaggingapi tag-resources \
  --resource-arn-list $(aws resource-groups list-group-resources \
    --group-name prod-health-notifications \
    --query 'ResourceIdentifiers[*].ResourceArn' \
    --output text) \
  --tags Compliance=SOC2
```

## Operational Notes

### Viewing Resource Group in Console

1. Navigate to **AWS Console → Resource Groups & Tag Editor**
2. Click on **Saved Resource Groups**
3. Select your group (e.g., `prod-health-notifications`)
4. View all associated resources, tags, and compliance status

### Managing Resources via CLI

```bash
# List all resource groups
aws resource-groups list-groups

# Get specific group details
aws resource-groups get-group \
  --group-name prod-health-notifications

# List resources in group
aws resource-groups list-group-resources \
  --group-name prod-health-notifications \
  --query 'ResourceIdentifiers[*].[ResourceType,ResourceArn]' \
  --output table

# Search for resources by tag
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=prod \
                Key=Service,Values=aws-health-notifications \
  --output table
```

## Monitoring

### CloudWatch Integration

Create dashboards for resource groups:

```bash
# Get resource ARNs for dashboard
RESOURCE_ARNS=$(aws resource-groups list-group-resources \
  --group-name prod-health-notifications \
  --query 'ResourceIdentifiers[*].ResourceArn' \
  --output text)

# Create CloudWatch dashboard for group
aws cloudwatch put-dashboard \
  --dashboard-name prod-health-notifications \
  --dashboard-body file://dashboard.json
```

### Cost Allocation Tags

Enable cost allocation tags in AWS Billing Console:
1. Go to **Billing → Cost Allocation Tags**
2. Activate tags: `Environment`, `Service`, `ManagedBy`, `Project`
3. Wait 24 hours for data to appear in Cost Explorer
4. Filter costs by tag to see resource group spending

## Best Practices

### Tagging Strategy

Always apply these tags to resources managed by this infrastructure:

```hcl
tags = {
  Environment = "prod"                    # Required: Environment identifier
  Service     = "aws-health-notifications" # Required: Service name
  ManagedBy   = "terraform"               # Required: Management method
  Project     = "aws-health-notifications" # Recommended: Project name
  Owner       = "platform-team"           # Recommended: Team/owner
  CostCenter  = "infrastructure"          # Optional: Cost center
}
```

### Resource Naming

Use consistent naming across all resources:
- `${environment}-health-event-notifications` for EventBridge rule
- `${environment}-health-event-formatter` for Lambda function
- `${environment}-health-notifications-resource-group` for resource group

## Troubleshooting

### Resources Not Appearing in Group

**Symptoms**: Resources don't show up in resource group

**Solutions**:
1. Verify resources have all required tags: `Environment`, `Service`, `ManagedBy`
2. Check tag values match exactly (case-sensitive)
3. Wait a few minutes for AWS to index new resources
4. Verify resource type is supported by Resource Groups

```bash
# Check resource tags
aws resourcegroupstaggingapi get-resources \
  --resource-arn-list arn:aws:sns:us-east-1:123456789012:prod-health-event-notifications \
  --query 'ResourceTagMappingList[*].Tags'
```

### Cannot Delete Resource Group

**Symptoms**: Resource group deletion fails

**Solutions**:
1. Resource groups can be deleted even with resources in them
2. Resources themselves are NOT deleted when you delete a resource group
3. If deletion fails, check IAM permissions for `resource-groups:DeleteGroup`

<!-- BEGIN_TF_DOCS -->
# Resource Groups Module

This module creates AWS Resource Groups to organize and manage all resources
associated with the AWS Health Notifications infrastructure.

## Features

- **Tag-Based Grouping**: Automatically groups resources using tag filters
- **Multi-Resource Support**: Supports all AWS resource types
- **Environment Isolation**: Separate resource groups per environment
- **Compliance Tracking**: Simplifies auditing and compliance reporting
- **Cost Allocation**: Enables cost tracking by resource group

## Resource Query

The resource group uses tag-based queries to automatically include resources with:
- `Environment = <environment>` (dev, prod, etc.)
- `Service = aws-health-notifications`
- `ManagedBy = terraform`

## Use Cases

- **Operations**: View all related resources in AWS Console in one place
- **Monitoring**: Apply CloudWatch dashboards and alarms to entire group
- **Cost Management**: Track costs for the entire notification system
- **Compliance**: Generate compliance reports for grouped resources
- **Automation**: Perform bulk operations on all resources in the group

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.22.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_resourcegroups_group.health_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod). Used for resource group naming and tag-based filtering. Groups all resources belonging to this environment's health notification infrastructure. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional resource tags to apply to the resource group itself. Note: The resource group filters resources based on Environment, Service, and ManagedBy tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_group_arn"></a> [group\_arn](#output\_group\_arn) | ARN of the resource group containing all health notification infrastructure. Use this ARN to apply group-level CloudWatch dashboards, cost allocation tags, or IAM policies. |
| <a name="output_group_name"></a> [group\_name](#output\_group\_name) | Name of the resource group. Use this name to view grouped resources in AWS Console Resource Groups & Tag Editor or generate compliance reports. |
<!-- END_TF_DOCS -->
