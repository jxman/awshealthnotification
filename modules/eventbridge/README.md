# EventBridge Health Notifications Module

This module creates an EventBridge rule that captures AWS Health Events and routes them through a Lambda function for formatting before sending to an SNS topic.

## Features

- **EventBridge Rule**: Captures all AWS Health Events from `aws.health` source
- **Lambda Formatter**: Node.js 20.x function that formats events into human-readable notifications
- **Environment Control**: Enable/disable notifications per environment without destroying resources
- **CloudWatch Logs**: Full logging integration for Lambda execution
- **Least-Privilege IAM**: Minimal permissions for Lambda execution (SNS publish + CloudWatch Logs)
- **Auto-Deployment**: Lambda code changes automatically detected and deployed via source hash

## Architecture

```
AWS Health Events → EventBridge Rule → Lambda Function → SNS Topic → Subscribers
```

## Usage Example

```hcl
module "eventbridge_notifications" {
  source = "../../modules/eventbridge"

  environment    = "prod"
  sns_topic_arn  = module.sns.topic_arn
  enabled        = true

  tags = {
    Project     = "aws-health-notifications"
    Owner       = "platform-team"
    CostCenter  = "infrastructure"
  }
}
```

### Disable Notifications in Dev Environment

```hcl
module "eventbridge_notifications" {
  source = "../../modules/eventbridge"

  environment    = "dev"
  sns_topic_arn  = module.sns.topic_arn
  enabled        = false  # Disable dev notifications

  tags = {
    Project     = "aws-health-notifications"
    Owner       = "platform-team"
  }
}
```

## Lambda Function

The Lambda function (Node.js 20.x) enhances AWS Health Event notifications with:
- Formatted event summaries with severity indicators
- Affected resource details
- Event timeline information
- Action recommendations

Lambda code is located in `./lambda/index.js` and automatically packaged as a ZIP file with change detection based on source hash.

### Testing Lambda Locally

```bash
# Navigate to lambda directory
cd modules/eventbridge/lambda

# Install dependencies (if any)
npm install

# Test with sample event
node -e "const handler = require('./index').handler; handler({detail: {...}}, {}, console.log)"
```

## Operational Notes

### Viewing Lambda Logs

```bash
# View recent logs
aws logs tail /aws/lambda/${environment}-health-event-formatter --follow

# View logs for specific time range
aws logs tail /aws/lambda/prod-health-event-formatter --since 1h
```

### Checking EventBridge Rule Status

```bash
# Check if rule is enabled
aws events describe-rule --name ${environment}-health-event-notifications

# Disable rule temporarily
aws events disable-rule --name prod-health-event-notifications

# Re-enable rule
aws events enable-rule --name prod-health-event-notifications
```

### Monitoring

Key metrics to monitor:
- **Lambda Invocations**: Number of health events processed
- **Lambda Errors**: Failed event processing
- **Lambda Duration**: Processing time per event
- **EventBridge TriggeredRules**: Number of events matched

## Security

- Lambda function uses least-privilege IAM role with only:
  - `sns:Publish` permission to the specific SNS topic
  - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` for CloudWatch Logs
- EventBridge rule has permission to invoke Lambda function
- No internet access required (uses VPC endpoints if in VPC)

## Cost Optimization

- Lambda: 128 MB memory, 30-second timeout (minimal cost)
- EventBridge: First 1M events/month free, then $1.00/million events
- Lambda invocations: Free tier includes 1M requests/month

For most AWS accounts, health events are infrequent (<100/month), resulting in minimal cost.

<!-- BEGIN_TF_DOCS -->
# EventBridge Health Notifications Module

This module creates an EventBridge rule that captures AWS Health Events and routes them
through a Lambda function for formatting before sending to an SNS topic.

## Features

- **EventBridge Rule**: Captures all AWS Health Events from aws.health source
- **Lambda Formatter**: Node.js 20.x function that formats events into human-readable notifications
- **Environment Control**: Enable/disable notifications per environment without destroying resources
- **CloudWatch Logs**: Full logging integration for Lambda execution
- **Least-Privilege IAM**: Minimal permissions for Lambda execution (SNS publish + CloudWatch Logs)
- **Auto-Deployment**: Lambda code changes automatically detected and deployed via source hash

## Event Flow

```
AWS Health Events → EventBridge Rule → Lambda Function → SNS Topic → Subscribers
```

## Lambda Function

The Lambda function (Node.js 20.x) enhances AWS Health Event notifications with:
- Formatted event summaries with severity indicators
- Affected resource details
- Event timeline information
- Action recommendations

Lambda code is located in `./lambda/` and automatically packaged as a ZIP file with
change detection based on source hash.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.22.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.health_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_sns_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.health_formatter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Enable or disable the EventBridge rule. When false, the rule exists but is in DISABLED state, preventing event processing without resource destruction. Useful for temporarily disabling notifications in non-prod environments. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod). Used for resource naming and tagging. Determines which environment's health events are captured. | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of the SNS topic where formatted health event notifications will be published. Lambda function will publish to this topic after formatting the event. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional resource tags to apply to all resources created by this module. These tags are merged with default tags (Environment, Service, ManagedBy). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function that formats health event notifications. Use this to invoke the function directly for testing or add additional triggers. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function. Use this to view logs in CloudWatch Logs (/aws/lambda/<name>) or update function configuration. |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARN of the IAM role used by the Lambda function. Reference this if you need to add additional permissions for the Lambda function. |
| <a name="output_rule_arn"></a> [rule\_arn](#output\_rule\_arn) | ARN of the EventBridge rule that captures AWS Health Events. Use this ARN for cross-account event bus permissions or CloudWatch monitoring. |
| <a name="output_rule_name"></a> [rule\_name](#output\_rule\_name) | Name of the EventBridge rule. Use this name to reference the rule in AWS Console or CLI commands for enabling/disabling or viewing event metrics. |
<!-- END_TF_DOCS -->
