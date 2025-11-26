# SNS Topic Module for Health Notifications

This module creates and configures an SNS topic for distributing AWS Health Event notifications to subscribers (email, SMS, Lambda, etc.).

## Features

- **SNS Topic**: Central notification distribution point for health events
- **Encryption**: AWS-managed KMS encryption at rest
- **EventBridge Integration**: Topic policy allows EventBridge to publish messages
- **Multi-Subscriber Support**: Can notify multiple endpoints (email, SMS, Lambda, SQS, etc.)
- **Environment Isolation**: Separate topics per environment (dev, prod)

## Architecture

```
EventBridge/Lambda → SNS Topic → Subscriptions (Email, SMS, Lambda, SQS, HTTP/S)
```

## Usage Example

### Basic Usage

```hcl
module "sns_topic" {
  source = "../../modules/sns"

  environment = "prod"

  tags = {
    Project     = "aws-health-notifications"
    Owner       = "platform-team"
    CostCenter  = "infrastructure"
  }
}
```

### With Email Subscription

```hcl
module "sns_topic" {
  source = "../../modules/sns"

  environment = "prod"

  tags = {
    Project = "aws-health-notifications"
  }
}

# Add email subscription (requires manual confirmation)
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = module.sns_topic.topic_arn
  protocol  = "email"
  endpoint  = "ops-team@example.com"
}
```

### With Multiple Subscriptions

```hcl
module "sns_topic" {
  source = "../../modules/sns"

  environment = "prod"
  tags        = { Project = "health-notifications" }
}

# Email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = module.sns_topic.topic_arn
  protocol  = "email"
  endpoint  = "team@example.com"
}

# SMS subscription
resource "aws_sns_topic_subscription" "sms" {
  topic_arn = module.sns_topic.topic_arn
  protocol  = "sms"
  endpoint  = "+12025551234"  # E.164 format
}

# Lambda subscription
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = module.sns_topic.topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.processor.arn
}
```

## Security

- **Encryption at Rest**: AWS-managed KMS key (`alias/aws/sns`)
- **Least-Privilege Policy**: Only EventBridge service can publish
- **No Public Access**: Subscribers must be explicitly added
- **HTTPS Delivery**: Encrypted in transit to HTTPS endpoints

## Operational Notes

### Adding Subscriptions via AWS CLI

```bash
# Add email subscription
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:prod-health-event-notifications \
  --protocol email \
  --notification-endpoint team@example.com

# Add SMS subscription
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:prod-health-event-notifications \
  --protocol sms \
  --notification-endpoint +12025551234

# List all subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:123456789012:prod-health-event-notifications
```

### Testing Notifications

```bash
# Send test message
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:123456789012:prod-health-event-notifications \
  --subject "Test Health Notification" \
  --message "This is a test message to verify SNS subscriptions are working."
```

### Monitoring

Key metrics to monitor:
- **NumberOfMessagesPublished**: Messages sent to topic
- **NumberOfNotificationsDelivered**: Successfully delivered notifications
- **NumberOfNotificationsFailed**: Failed deliveries (check dead-letter queue)

```bash
# View SNS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/SNS \
  --metric-name NumberOfMessagesPublished \
  --dimensions Name=TopicName,Value=prod-health-event-notifications \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Subscription Types

| Protocol | Use Case | Confirmation Required | Example Endpoint |
|----------|----------|----------------------|------------------|
| `email` | Team notifications | Yes | `team@example.com` |
| `email-json` | Raw JSON to email | Yes | `devs@example.com` |
| `sms` | Critical alerts | No | `+12025551234` |
| `https` | Webhooks | Yes | `https://api.example.com/webhook` |
| `lambda` | Event processing | No | `arn:aws:lambda:...` |
| `sqs` | Async processing | No | `arn:aws:sqs:...` |
| `application` | Mobile push | No | `arn:aws:sns:...:endpoint/...` |

## Cost Optimization

- **Email**: $0 (free)
- **SMS**: $0.00645 per SMS in US (varies by country)
- **HTTP/S**: $0.60 per 1M notifications
- **Lambda/SQS**: $0.50 per 1M notifications
- **Mobile Push**: $0.50 per 1M notifications

Most health notification use cases result in minimal cost (<$1/month).

## Troubleshooting

### Email Subscription Not Receiving Messages

1. Check spam/junk folder
2. Verify subscription is confirmed: `aws sns list-subscriptions-by-topic --topic-arn <ARN>`
3. Check subscription status is `Confirmed`, not `PendingConfirmation`

### SMS Delivery Failures

1. Verify phone number is in E.164 format (+[country code][number])
2. Check AWS account SMS spending limit: AWS Console → SNS → Text messaging (SMS)
3. Verify phone number is not in the SNS SMS sandbox (if in sandbox, only verified numbers work)

### Lambda Not Being Triggered

1. Verify Lambda has SNS invoke permission
2. Check Lambda execution role has necessary permissions
3. View Lambda metrics for invocation count

<!-- BEGIN_TF_DOCS -->
# SNS Topic Module for Health Notifications

This module creates and configures an SNS topic for distributing AWS Health Event
notifications to subscribers (email, SMS, Lambda, etc.).

## Features

- **SNS Topic**: Central notification distribution point for health events
- **Encryption**: AWS-managed KMS encryption at rest
- **EventBridge Integration**: Topic policy allows EventBridge to publish messages
- **Multi-Subscriber Support**: Can notify multiple endpoints (email, SMS, Lambda, SQS, etc.)
- **Environment Isolation**: Separate topics per environment (dev, prod)

## Security

- Encrypted at rest using AWS-managed KMS key (alias/aws/sns)
- Least-privilege topic policy (only EventBridge can publish)
- No public access - subscribers must be explicitly added

## Usage Notes

Subscribers must be added separately after topic creation:
- Email subscriptions require confirmation
- SMS subscriptions require phone number in E.164 format
- Lambda subscriptions require appropriate IAM permissions

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
| [aws_sns_topic.health_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod). Used for SNS topic naming and tagging. Creates isolated notification topics per environment. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional resource tags to apply to SNS topic and related resources. These tags are merged with default tags (Environment, Service, ManagedBy, SubService). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_topic_arn"></a> [topic\_arn](#output\_topic\_arn) | ARN of the SNS topic for health event notifications. Use this ARN to create subscriptions (email, SMS, Lambda, SQS) or grant publish permissions to other services. |
| <a name="output_topic_id"></a> [topic\_id](#output\_topic\_id) | ID of the SNS topic (same as ARN). Provided for compatibility with modules that expect an ID output. |
| <a name="output_topic_name"></a> [topic\_name](#output\_topic\_name) | Name of the SNS topic. Use this name to reference the topic in AWS Console or CLI commands for managing subscriptions and viewing metrics. |
<!-- END_TF_DOCS -->
