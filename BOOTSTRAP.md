# Bootstrap Guide - GitHub Actions Setup

This guide will help you set up the AWS Health Notifications infrastructure for the first time using GitHub Actions CI/CD.

## Overview

This project **exclusively uses GitHub Actions** for all deployments. There are no local deployment scripts. All infrastructure changes are deployed through the automated CI/CD pipeline.

## Prerequisites

Before you begin, ensure you have:

- ✅ **AWS Account** with administrative access
- ✅ **GitHub Account** with repository access
- ✅ **AWS CLI** installed and configured locally (for verification only)
- ✅ **Terraform** v1.0.0+ installed locally (for local validation only, not deployment)
- ✅ **Git** installed locally

## Step 1: Create AWS S3 Backend Bucket

The Terraform state is stored in S3. Create the backend bucket first:

```bash
# Set your AWS region
export AWS_REGION=us-east-1

# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket my-terraform-state-bucket-$(date +%s) \
  --region $AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket-XXXXX \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket-XXXXX \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket my-terraform-state-bucket-XXXXX \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

**Note the bucket name** - you'll need it for GitHub Secrets.

## Step 2: Create AWS IAM User for GitHub Actions

Create a dedicated IAM user with appropriate permissions:

```bash
# Create IAM user
aws iam create-user --user-name github-actions-terraform

# Create access keys
aws iam create-access-key --user-name github-actions-terraform
```

**Save the Access Key ID and Secret Access Key** - you'll need them for GitHub Secrets.

### Attach IAM Policy

Create a policy file `github-actions-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:*",
        "lambda:*",
        "sns:*",
        "iam:*",
        "logs:*",
        "resource-groups:*",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
```

Apply the policy:

```bash
# Create the policy
aws iam put-user-policy \
  --user-name github-actions-terraform \
  --policy-name TerraformDeployment \
  --policy-document file://github-actions-policy.json
```

**⚠️ For production, use more restrictive policies following least-privilege principles.**

## Step 3: Configure GitHub Repository

### 3.1 Configure GitHub Secrets

Go to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name              | Value                              | Example                      |
| ------------------------ | ---------------------------------- | ---------------------------- |
| `AWS_ACCESS_KEY_ID`      | From Step 2 IAM user creation      | `AKIAIOSFODNN7EXAMPLE`       |
| `AWS_SECRET_ACCESS_KEY`  | From Step 2 IAM user creation      | `wJalrXUtnFEMI/K7MDENG/...`  |
| `TF_STATE_BUCKET`        | S3 bucket name from Step 1         | `my-terraform-state-bucket-123` |

### 3.2 Configure GitHub Environments

**Settings → Environments → New environment**

Create two environments:

#### Development Environment (`dev`)

- **Name**: `dev`
- **Protection rules**: None (auto-deploy on merge)
- **Deployment branches**: Only `main` branch

#### Production Environment (`prod`)

- **Name**: `prod`
- **Protection rules**:
  - ✅ Required reviewers (add 1+ team members)
  - ✅ Wait timer: 0 minutes (optional)
- **Deployment branches**: Only `main` branch

## Step 4: Configure Environment Variables

### 4.1 Create Development Configuration

Edit `environments/dev/terraform.tfvars`:

```hcl
# Development Environment Configuration
aws_region  = "us-east-1"
environment = "dev"

# Tagging (required)
tags = {
  Environment  = "dev"
  Service      = "aws-health-notifications"
  ManagedBy    = "terraform"
  Owner        = "Your Team Name"
  GithubRepo   = "your-org/aws-health-notifications"
  Project      = "aws-health-notifications"
  Site         = "N/A"
  BaseProject  = "aws-health-notifications"
  CostCenter   = "engineering"
}
```

### 4.2 Create Production Configuration

Edit `environments/prod/terraform.tfvars`:

```hcl
# Production Environment Configuration
aws_region  = "us-east-1"
environment = "prod"

# Tagging (required)
tags = {
  Environment  = "prod"
  Service      = "aws-health-notifications"
  ManagedBy    = "terraform"
  Owner        = "Your Team Name"
  GithubRepo   = "your-org/aws-health-notifications"
  Project      = "aws-health-notifications"
  Site         = "N/A"
  BaseProject  = "aws-health-notifications"
  CostCenter   = "engineering"
}
```

**⚠️ Do NOT commit `terraform.tfvars` files if they contain sensitive information.**

## Step 5: Verify Backend Configuration

Check that backend configs are correct:

**`backend/dev.hcl`:**
```hcl
bucket       = "your-s3-bucket-name"
key          = "health-notifications/dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

**`backend/prod.hcl`:**
```hcl
bucket       = "your-s3-bucket-name"
key          = "health-notifications/prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

**Note**: The GitHub Actions workflow will override the bucket name with the `TF_STATE_BUCKET` secret.

## Step 6: Initial Deployment

### 6.1 Local Validation (Optional)

You can validate locally before deploying (no changes applied):

```bash
# Navigate to dev environment
cd environments/dev

# Initialize Terraform (read-only)
terraform init -backend-config=../../backend/dev.hcl

# Validate configuration
terraform validate

# Preview changes (does NOT apply)
terraform plan -var-file="terraform.tfvars"

# Go back to root
cd ../..
```

**❌ NEVER run `terraform apply` locally!**

### 6.2 Deploy via GitHub Actions

#### Option A: Push to Main (Auto-Deploy to Dev)

```bash
# Create feature branch
git checkout -b feature/initial-setup

# Stage your tfvars changes
git add environments/dev/terraform.tfvars environments/prod/terraform.tfvars

# Commit
git commit -m "feat: initial environment configuration"

# Push
git push origin feature/initial-setup

# Create PR on GitHub
# Review the Terraform plan in PR checks
# Merge to main → Automatically deploys to dev
```

#### Option B: Manual Workflow Dispatch

1. Go to **GitHub → Actions**
2. Click **"Terraform CI/CD"** workflow
3. Click **"Run workflow"**
4. Select **environment**: `dev`
5. Click **"Run workflow"**
6. Monitor the deployment

### 6.3 Verify Dev Deployment

After deployment completes:

```bash
# Check Lambda function
aws lambda get-function \
  --function-name dev-health-event-formatter \
  --region us-east-1

# Check EventBridge rule
aws events describe-rule \
  --name dev-health-event-notifications \
  --region us-east-1

# Check SNS topic
aws sns list-topics \
  --region us-east-1 | grep dev-health-event-notifications
```

## Step 7: Configure SNS Subscriptions

SNS subscriptions are managed manually via AWS Console:

### Email Subscription

1. Go to **AWS Console → SNS → Topics**
2. Select `dev-health-event-notifications`
3. Click **"Create subscription"**
4. Protocol: `Email`
5. Endpoint: `your-email@company.com`
6. Click **"Create subscription"**
7. Check email and confirm subscription

### SMS Subscription (Optional)

1. Same steps as email
2. Protocol: `SMS`
3. Endpoint: `+1234567890` (E.164 format)

## Step 8: Production Deployment

Once dev is working:

```bash
# Create production feature branch
git checkout -b feature/prod-deployment

# Ensure prod tfvars are configured
# Commit if needed
git add environments/prod/terraform.tfvars
git commit -m "feat: production environment configuration"

# Push and create PR
git push origin feature/prod-deployment
```

After PR merge:

1. Go to **GitHub → Actions**
2. Click **"Terraform CI/CD"** workflow
3. Click **"Run workflow"**
4. Select **environment**: `prod`
5. Click **"Run workflow"**
6. **Review the plan carefully**
7. Click **"Review deployments"**
8. Select `prod` environment
9. Click **"Approve and deploy"**

## Step 9: Test the System

### Test Dev Environment

```bash
# Use the testing script
./scripts/testing/test-health-notification.sh dev
```

Or manually:

```bash
# Create a test event
aws events put-events \
  --entries '[{
    "Source": "aws.health",
    "DetailType": "AWS Health Event",
    "Detail": "{\"service\":\"EC2\",\"statusCode\":\"open\",\"eventTypeCode\":\"AWS_EC2_INSTANCE_RETIREMENT\",\"eventTypeCategory\":\"scheduledChange\"}"
  }]' \
  --region us-east-1
```

Check your email for the notification.

## Troubleshooting

### GitHub Actions Workflow Fails

**Check:**
- GitHub Secrets are configured correctly
- AWS credentials have appropriate permissions
- S3 backend bucket exists and is accessible
- Backend configs point to correct bucket

### No Notifications Received

**Check:**
- EventBridge rule is `ENABLED` (dev is disabled by default)
- SNS subscriptions are confirmed
- Lambda function has no errors (check CloudWatch Logs)
- Email is not in spam folder

### State Lock Errors

**Check:**
- No other workflow is running
- Previous workflow completed successfully
- S3 bucket is accessible

**Fix (last resort):**
```bash
# Manually remove lock file from S3
aws s3 rm s3://your-bucket/health-notifications/dev/.terraform.lock
```

## Maintenance

### Update Lambda Code

1. Edit `modules/eventbridge/lambda/index.js`
2. Create PR with changes
3. Merge to main → Auto-deploys to dev
4. Test in dev
5. Deploy to prod via workflow dispatch

### Update Infrastructure

1. Edit Terraform modules in `modules/`
2. Create PR with changes
3. Review plan in PR checks
4. Merge to main → Auto-deploys to dev
5. Test in dev
6. Deploy to prod via workflow dispatch

### Cleanup Local Files

```bash
# Clean up generated Terraform files
./scripts/utilities/cleanup-project.sh
```

## Security Best Practices

- ✅ Use least-privilege IAM policies
- ✅ Rotate AWS credentials regularly
- ✅ Enable S3 bucket encryption
- ✅ Use GitHub environment protection rules for prod
- ✅ Review all Terraform plans before applying
- ✅ Never commit AWS credentials to repository
- ✅ Enable CloudTrail for audit logging

## Next Steps

Once bootstrap is complete:

1. ✅ Configure monitoring and alerting (see README.md)
2. ✅ Set up CloudWatch dashboards
3. ✅ Document runbooks for common operations
4. ✅ Train team on GitHub Actions workflow
5. ✅ Set up regular security reviews

## Support

For issues or questions:

- **Documentation**: [README.md](README.md), [deployment.md](deployment.md)
- **GitHub Issues**: Report bugs and feature requests
- **Team**: Contact Platform Team

---

**Congratulations!** 🎉 Your AWS Health Notifications infrastructure is now running with GitHub Actions CI/CD!
