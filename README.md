# AWS Health Event Notifications Infrastructure

This project manages AWS Health Event notifications using Terraform and GitHub Actions, supporting multiple environments with email and SMS notifications.

## Architecture

- Amazon EventBridge for AWS Health event capture
- Amazon SNS for notifications (email and SMS)
- Terraform for infrastructure management
- GitHub Actions for CI/CD

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository access
- Terraform (v1.10.1 or higher)
- AWS CLI configured locally

## Project Structure

```
.
├── README.md
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars (gitignored)
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars (gitignored)
├── modules/
│   ├── eventbridge/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── sns/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .github/
    └── workflows/
        └── terraform.yml
```

## Local Setup

1. Clone repository:

```bash
git clone <repository-url>
cd aws-health-notifications
```

2. Create environment backend.hcl (do not commit):

```hcl
bucket         = "your-terraform-state-bucket"
key            = "health-notifications/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "your-terraform-lock-table"
encrypt        = true
```

3. Create environment tfvars (do not commit):

```hcl
aws_region                     = "us-east-1"
environment                    = "dev"  # or "prod"
email_addresses                = ["email1@example.com", "email2@example.com"]
phone_numbers                  = ["1234567890"]
terraform_state_bucket         = "your-terraform-state-bucket"
terraform_state_key            = "health-notifications/dev/terraform.tfstate"
terraform_state_dynamodb_table = "your-terraform-lock-table"
```

## GitHub Setup

1. Configure GitHub Environments (dev and prod)
2. Add Environment Secrets:
   ```
   DEV_NOTIFICATION_EMAIL: ["dev-email1@example.com"]
   DEV_NOTIFICATION_PHONE: ["1234567890"]
   PROD_NOTIFICATION_EMAIL: ["prod-email1@example.com"]
   PROD_NOTIFICATION_PHONE: ["1234567890"]
   ```
3. Add Repository Secrets:
   ```
   AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY
   TF_STATE_BUCKET
   TF_STATE_LOCK_TABLE
   ```

## Deployment

### Automated (GitHub Actions)

- Pull Requests: Terraform plan only
- Push to main: Automatic dev deployment
- Manual trigger: Select environment (dev/prod)

### Manual (Local)

```bash
cd environments/dev  # or prod
terraform init -backend-config=../../backend.hcl
terraform plan
terraform apply
```

## Contributing

1. Create feature branch:

```bash
git checkout -b feature/your-feature-name
```

2. Make changes and commit:

```bash
git add .
git commit -m "feat: your feature description"
```

3. Push and create PR:

```bash
git push origin feature/your-feature-name
```

## License

MIT License
