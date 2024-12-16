# AWS Health Events Notification System

This Terraform configuration sets up an automated notification system for AWS Health Events. The system captures AWS Health Events and forwards them to multiple email addresses through SNS in a readable format.

## Architecture

The solution uses the following AWS services:

- Amazon EventBridge (CloudWatch Events) to capture AWS Health Events
- Amazon SNS to send email notifications
- IAM roles and policies for service integration

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
├── main.tf           # Main infrastructure configuration
├── variables.tf      # Variable definitions
├── outputs.tf        # Output definitions
├── versions.tf       # Provider and terraform version constraints
├── terraform.tfvars  # Variable values (git-ignored)
└── .gitignore
```

## Configuration

1. Clone this repository:

```bash
git clone <repository-url>
cd health-notifications
```

2. Create a `terraform.tfvars` file with your configuration:

```hcl
aws_region                     = "us-east-1"
email_addresses                = ["email1@example.com", "email2@example.com"]
terraform_state_bucket         = "your-terraform-state-bucket"
terraform_state_key            = "health-notifications/terraform.tfstate"
terraform_state_dynamodb_table = "your-terraform-lock-table"
```

3. Initialize Terraform with backend configuration:

```bash
terraform init -backend-config=backend.hcl
```

4. Review the planned changes:

```bash
terraform plan
```

5. Apply the configuration:

```bash
terraform apply
```

6. Each email address will receive a confirmation email that must be confirmed to receive notifications.

## GitHub Actions Configuration

The repository includes a GitHub Actions workflow that automates the deployment process. Required secrets:

- `AWS_ACCESS_KEY_ID`: AWS access key for authentication
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for authentication
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state
- `TF_STATE_LOCK_TABLE`: DynamoDB table name for state locking
- `NOTIFICATION_EMAILS`: JSON array of email addresses (e.g., `["email1@example.com", "email2@example.com"]`)

## Testing

To test the notification system:

1. Go to the AWS EventBridge console
2. Navigate to 'Rules'
3. Select the 'health-event-notifications' rule
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
terraform destroy
```

## Customization

You can customize the notification format by modifying the `input_template` in `main.tf`. The template supports the following fields:

- Event Source
- Event Type
- Event ARN
- Time Detected
- Start Time
- End Time
- Region
- Account
- Service Affected
- Event Type Code
- Category
- Status
- Description

## Troubleshooting

1. **No confirmation emails received:**

   - Check your spam folder
   - Verify the email addresses in terraform.tfvars
   - Confirm the SNS topic was created successfully

2. **No notifications received:**

   - Verify you confirmed the SNS subscription
   - Check the EventBridge rule is enabled
   - Verify the IAM permissions are correct

3. **Error during terraform apply:**

   - Ensure your AWS credentials have appropriate permissions
   - Verify the region setting in provider configuration
   - Check for any resource naming conflicts

4. **GitHub Actions issues:**
   - Verify all required secrets are set correctly
   - Check the workflow logs for specific error messages
   - Ensure the NOTIFICATION_EMAILS secret is a valid JSON array

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
