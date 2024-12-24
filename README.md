# AWS Health Events Notification System

An automated notification system that monitors AWS Health Events and sends notifications via SNS.

## Author

**John Xanthopoulos**

- GitHub: [jxman](https://github.com/jxman)

## Version

- Current Version: 1.0.0
- Last Updated: December 2024
- Initial Release: December 2024

## Changelog

### 1.0.0 (2024-12-16)

- Initial release with core functionality:
  - AWS Health Events monitoring setup
  - SNS notification system with multi-email support
  - Terraform configuration with state management
  - GitHub Actions CI/CD pipeline with plan approval workflow
  - Comprehensive documentation and testing guide
  - Modular infrastructure design with environment support

## Architecture

The solution uses the following AWS services:

- Amazon EventBridge (CloudWatch Events) to capture AWS Health Events
- Amazon SNS to send email notifications
- IAM roles and policies for service integration
- S3 bucket for Terraform state management
- DynamoDB table for state locking

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (version >= 1.0.0)
- AWS CLI configured with appropriate credentials
- One or more email addresses to receive notifications
- S3 bucket for Terraform state
- DynamoDB table for state locking

## Directory Structure

```
health-notifications/
├── README.md
├── modules/
│   ├── eventbridge/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── sns/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── backend/
│   ├── dev.hcl
│   └── prod.hcl
└── .github/
    └── workflows/
```

## Local Configuration

1. Clone this repository:

```bash
git clone <repository-url>
cd health-notifications
```

2. Create environment-specific backend config (do not commit):

```hcl
# backend/prod.hcl
bucket         = "your-terraform-state-bucket"
key            = "health-notifications/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "your-terraform-lock-table"
encrypt        = true
```

3. Create environment-specific tfvars (do not commit):

```hcl
# environments/prod/terraform.tfvars
aws_region                     = "us-east-1"
environment                    = "prod"
email_addresses                = ["email1@example.com", "email2@example.com"]
terraform_state_bucket         = "your-terraform-state-bucket"
terraform_state_key            = "health-notifications/prod/terraform.tfstate"
terraform_state_dynamodb_table = "your-terraform-lock-table"
```

4. Use the initialization script:

```bash
./init.sh prod  # or ./init.sh dev
```

5. Use the deployment script:

```bash
./deploy.sh prod  # or ./deploy.sh dev
```

## Modules

### SNS Module

The SNS module manages notification infrastructure:

- Creates environment-specific SNS topics
- Manages email subscriptions
- Configures topic policies for EventBridge integration

### EventBridge Module

The EventBridge module handles event processing:

- Creates environment-specific rules
- Configures event patterns for Health events
- Manages target configuration and message formatting

## GitHub Actions Configuration

The repository includes a GitHub Actions workflow that automates the deployment process. Required secrets:

- `AWS_ACCESS_KEY_ID`: AWS access key for authentication
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for authentication
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state
- `TF_STATE_LOCK_TABLE`: DynamoDB table name for state locking
- `NOTIFICATION_EMAILS`: JSON array of email addresses (e.g., `["email1@example.com", "email2@example.com"]`)

### Setting up GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the required secrets listed above
4. Configure environment protection rules for 'dev' and 'prod'

### Workflow Features

- Environment-specific deployments (dev/prod)
- Manual workflow trigger with environment selection
- Separate state files per environment
- Environment-specific approvals
- Recursive format checking
- Modular resource management

### Workflow Process

1. Run Terraform format check (recursively through modules)
2. Initialize Terraform with environment-specific backend
3. Validate the configuration
4. Create a plan
5. Require environment-specific approval
6. Apply changes after approval

## Testing

To test the notification system:

1. Go to the AWS EventBridge console
2. Navigate to 'Rules'
3. Select the '{env}-health-event-notifications' rule
4. Click 'Test pattern'
5. Use this sample event:

```json
{
  "version": "0",
  "id": "7bf73129-1428-4cd3-a780-95db273d1602",
  "detail-type": "AWS Health Event",
  "source": "aws.health",
  "account": "123456789012",
  "time": "2023-01-26T01:43:21Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "eventArn": "arn:aws:health:us-east-1::event/AWS_ELASTICLOADBALANCING_API_ISSUE_90353408594353980",
    "service": "ELASTICLOADBALANCING",
    "eventTypeCode": "AWS_ELASTICLOADBALANCING_OPERATIONAL_ISSUE",
    "eventTypeCategory": "issue",
    "eventScopeCode": "PUBLIC",
    "startTime": "Thu, 26 Jan 2023 13:19:03 GMT",
    "endTime": "Thu, 26 Jan 2023 13:44:13 GMT",
    "statusCode": "open",
    "eventRegion": "us-east-1",
    "eventDescription": [
      {
        "language": "en_US",
        "latestDescription": "This is a test notification for AWS Health Event"
      }
    ]
  }
}
```

## Outputs

After applying the configuration, you'll see these outputs:

- `sns_topic_arn`: The ARN of the created SNS topic
- `eventbridge_rule_arn`: The ARN of the EventBridge rule

## Clean Up

To remove all created resources:

```bash
./deploy.sh prod destroy  # or ./deploy.sh dev destroy
```

## Troubleshooting

1. **No confirmation emails received:**

   - Check your spam folder
   - Verify the email addresses in terraform.tfvars
   - Confirm the SNS topic was created successfully

2. **No notifications received:**

   - Verify you confirmed the SNS subscription
   - Check the EventBridge rule is enabled
   - Verify the IAM permissions are correct

3. **GitHub Actions issues:**

   - Verify all required secrets are set correctly
   - Check the workflow logs for specific error messages
   - Ensure the NOTIFICATION_EMAILS secret is a valid JSON array

4. **State management issues:**
   - Verify your backend.hcl configuration
   - Check S3 bucket and DynamoDB table permissions
   - Ensure the state file path is correct

## Security Notes

- Never commit backend.hcl or terraform.tfvars files
- Keep AWS credentials secure and rotate them regularly
- Use IAM roles with minimum required permissions
- Enable S3 bucket encryption for state files
- Enable DynamoDB encryption for state locking
- Use environment-specific approvals in GitHub Actions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License

Copyright (c) 2024 John Xanthopoulos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
