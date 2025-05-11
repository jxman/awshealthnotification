# AWS Health Event Notifications Infrastructure

This project automates AWS Health Event notifications using Terraform and GitHub Actions, supporting multiple environments with customizable email and SMS alerts.

## Features

- 🔔 Real-time AWS Health Event notifications
- 📧 Enhanced email formatting with emojis and visual structure
- 🌍 Multi-environment support (dev/prod)
- 🔄 Automated deployments via GitHub Actions
- 🔒 State management with S3 and DynamoDB
- 📝 Custom message formatting with Lambda function
- 🏗️ Modular Terraform architecture

## Architecture

```
AWS Health Events → EventBridge → Lambda Function → SNS Topic → Email/SMS Subscribers
```

- **Amazon EventBridge**: Captures and filters AWS Health events
- **AWS Lambda**: Formats notifications with enhanced readability
- **Amazon SNS**: Manages notification distribution
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD automation

## Project Structure

```
.
├── environments/
│   ├── dev/            # Development environment
│   └── prod/           # Production environment
├── modules/
│   ├── eventbridge/    # Event processing & Lambda formatting
│   │   └── lambda/     # Lambda code for formatting notifications
│   └── sns/            # Notification management module
├── backend/            # Backend configurations
├── .github/workflows/  # CI/CD pipeline
└── scripts/            # Helper scripts
```

## Prerequisites

- AWS Account with administrative access
- GitHub repository access
- Terraform v1.10.1 or higher
- AWS CLI configured locally
- S3 bucket for Terraform state
- DynamoDB table for state locking

## GitHub Setup

### 1. Configure Environments

Create two GitHub environments: `dev` and `prod`.

### 2. Repository Secrets

```
AWS_ACCESS_KEY_ID: Your AWS access key
AWS_SECRET_ACCESS_KEY: Your AWS secret key
TF_STATE_BUCKET: Your S3 bucket name
TF_STATE_LOCK_TABLE: Your DynamoDB table name
```

## Local Development

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aws-health-notifications
```

### 2. Initialize Environment

```bash
# Use the init script for automated setup
./init.sh dev

# Or manually:
cd environments/dev
terraform init -backend-config=../../backend/dev.hcl
```

### 3. Create tfvars File

Copy the example and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Deploy Locally

```bash
# Using the deploy script
./deploy.sh dev

# Or manually:
terraform plan
terraform apply
```

## CI/CD Pipeline

### Automated Deployments

- **Pull Requests**: Terraform plan only (for review)
- **Push to main**: Automatic deployment to dev
- **Manual trigger**: Select environment for deployment

### Deployment Flow

1. Create feature branch
2. Make changes
3. Create pull request
4. Review Terraform plan
5. Merge to main
6. Automatic deployment (dev) or manual approval (prod)

### Production Deployments

Production requires manual approval through GitHub environments:

1. Merge PR to main
2. GitHub Actions runs Terraform plan
3. Review and approve deployment in GitHub UI
4. Terraform apply executes

## Notification Format

The notifications are formatted by a Lambda function for improved readability:

### Email Notifications

```
=====================================================================
            ⚠️  AWS HEALTH EVENT - DEV ENVIRONMENT  ⚠️
=====================================================================

📊  EVENT SUMMARY
    -------------------------------------------------------------
    • Service:    EC2
    • Status:     OPEN
    • Type:       AWS_EC2_OPERATIONAL_ISSUE
    • Category:   issue

🕒  TIMELINE
    -------------------------------------------------------------
    • Detected:   2025-05-11T12:00:00Z
    • Started:    2025-05-11T11:45:00Z
    • Ended:      2025-05-11T12:30:00Z

📝  DESCRIPTION
    -------------------------------------------------------------
    We are experiencing elevated API error rates for EC2 instances
    in the US-EAST-1 region. Our engineering team is investigating
    the issue.

🔍  EVENT DETAILS
    -------------------------------------------------------------
    • Event ARN:  arn:aws:health:us-east-1::event/EC2/...
    • Region:     us-east-1
    • Account:    123456789012

=====================================================================
                 AWS HEALTH EVENT MONITORING SYSTEM
=====================================================================
```

### SMS Notifications

Concise format:

```
⚠️ DEV ALERT: EC2 OPEN - AWS_EC2_OPERATIONAL_ISSUE
```

## Managing Subscriptions

SNS topic subscriptions are managed manually through the AWS Console, not through Terraform. This approach provides more flexibility and avoids issues with subscription confirmation and state management.

### Adding Email Subscriptions

1. Navigate to the AWS SNS Console
2. Find the topic: `{environment}-health-event-notifications`
3. Click "Create subscription"
4. Choose:
   - Protocol: Email
   - Endpoint: Enter the email address
5. Click "Create subscription"
6. Check the email inbox and confirm the subscription

### Adding SMS Subscriptions

1. Navigate to the AWS SNS Console
2. Find the topic: `{environment}-health-event-notifications`
3. Click "Create subscription"
4. Choose:
   - Protocol: SMS
   - Endpoint: Enter the phone number in E.164 format (e.g., +14155551234)
5. Click "Create subscription"

## Testing Notifications

To test the notification system:

```bash
# Create a test script
cat > test-health-event.sh << 'EOF'
#!/bin/bash
# Test script for AWS Health Event notifications

ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"
EVENT_ID=$(date +%s)

# Find the Lambda function
LAMBDA_NAME=$(aws lambda list-functions \
  --query "Functions[?contains(FunctionName, '${ENVIRONMENT}-health-event-formatter')].FunctionName" \
  --output text \
  --region "${REGION}")

# Create a test event
cat > test-event.json << EOF2
{
  "source": "aws.health",
  "detail-type": "AWS Health Event",
  "time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "region": "${REGION}",
  "account": "$(aws sts get-caller-identity --query Account --output text)",
  "detail": {
    "eventArn": "arn:aws:health:${REGION}::event/EC2/AWS_EC2_OPERATIONAL_ISSUE/TEST_${EVENT_ID}",
    "service": "EC2",
    "eventTypeCode": "AWS_EC2_OPERATIONAL_ISSUE",
    "eventTypeCategory": "issue",
    "startTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "endTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "statusCode": "open",
    "eventDescription": [
      {
        "language": "en_US",
        "latestDescription": "TEST NOTIFICATION: This is a test AWS Health event to verify formatting. Test ID: ${EVENT_ID}"
      }
    ]
  }
}
EOF2

# Invoke the Lambda function
aws lambda invoke \
  --function-name "$LAMBDA_NAME" \
  --payload file://test-event.json \
  --cli-binary-format raw-in-base64-out \
  --region "${REGION}" \
  response.json

echo "Test event sent! Check your email for the notification."
rm test-event.json response.json
EOF

chmod +x test-health-event.sh
./test-health-event.sh
```

## Best Practices

1. **Testing**: Always test changes in dev before prod
2. **Reviews**: Require PR reviews for all changes
3. **Monitoring**: Watch CloudWatch logs for event processing
4. **Validation**: Verify SNS subscriptions after deployment
5. **Documentation**: Keep tfvars.example updated

## Troubleshooting

### Common Issues

1. **Failed Terraform Init**

   - Check S3 bucket permissions
   - Verify DynamoDB table exists
   - Confirm AWS credentials

2. **Subscription Confirmation**

   - Check spam folders for confirmation emails
   - Verify phone numbers are in E.164 format

3. **No Notifications Received**

   - Confirm EventBridge rule is active
   - Check SNS topic permissions
   - Review CloudWatch logs for Lambda function
   - Verify subscription status in SNS

4. **Lambda Errors**
   - Check CloudWatch Logs under `/aws/lambda/{environment}-health-event-formatter`
   - Verify Lambda role permissions
   - Check if the Lambda function has access to SNS

## Support

- Check GitHub Actions logs for deployment issues
- Review AWS CloudWatch for event processing logs
- Contact the platform team for assistance

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request
5. Wait for review and approval

## Changelog

See [deployment.md](deployment.md) for detailed deployment procedures.
