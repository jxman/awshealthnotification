# AWS Health Event Notifications Infrastructure

This project automates AWS Health Event notifications using Terraform and GitHub Actions, supporting multiple environments with customizable email and SMS alerts.

## Features

- 🔔 Real-time AWS Health Event notifications
- 📧 Email and SMS notification channels
- 🌍 Multi-environment support (dev/prod)
- 🔄 Automated deployments via GitHub Actions
- 🔒 State management with S3 and DynamoDB
- 📝 Custom message formatting per channel
- 🏗️ Modular Terraform architecture

## Architecture

```
AWS Health Events → EventBridge → SNS Topic → Email/SMS Subscribers
```

- **Amazon EventBridge**: Captures and filters AWS Health events
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
│   ├── eventbridge/    # Event processing module
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

### 2. Environment Secrets

For each environment, add:

```
<ENV>_NOTIFICATION_EMAIL: ["email1@example.com", "email2@example.com"]
<ENV>_NOTIFICATION_PHONE: ["+1234567890", "+0987654321"]
```

### 3. Repository Secrets

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

## Notification Formats

### Email Notifications

Detailed information including:

- Environment name
- Event details and description
- Affected service
- Time information
- AWS account and region

### SMS Notifications

Concise format:

```
[Environment] AWS Health Alert: <Service> is <Status>. <Description>
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
   - Review CloudWatch logs

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
