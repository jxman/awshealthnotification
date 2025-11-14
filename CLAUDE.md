# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a **Terraform-managed AWS Health Notifications Infrastructure** that automates AWS Health Event notifications using:
- **EventBridge** - Captures and filters AWS Health events
- **Lambda** (Node.js 20.x) - Formats notifications with enhanced readability
- **SNS** - Manages notification distribution to subscribers
- **S3 backend** with native locking for state management

### Event Flow
```
AWS Health Events → EventBridge → Lambda Function → SNS Topic → Email/SMS
```

### Environment Structure
- `environments/dev/` - Development environment config
- `environments/prod/` - Production environment config
- `modules/` - Reusable Terraform modules (eventbridge, sns, resource_groups)
- `backend/` - S3 backend configurations (*.hcl files)

## Common Commands

### Environment Management
```bash
# Initialize environment (sets up backend, validates config)
./init.sh dev
./init.sh prod

# Deploy infrastructure
./deploy.sh dev
./deploy.sh prod

# Validate backend configuration
./validate-backend.sh
```

### Manual Terraform Operations
```bash
cd environments/dev
terraform init -backend-config=../../backend/dev.hcl
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Log Management
```bash
# Manage deployment logs
./manage-logs.sh
```

## Key Architecture Details

### Module Dependencies
1. **SNS module** creates topic first
2. **EventBridge module** depends on SNS topic ARN
3. **Lambda function** auto-packages from `modules/eventbridge/lambda/` with change detection

### State Management
- S3 backend with `use_lockfile = true` for native locking
- State keys: `health-notifications/{env}/terraform.tfstate`
- Backend configs in `backend/{env}.hcl`

### Lambda Function
- Located at `modules/eventbridge/lambda/index.js`
- Uses AWS SDK v3 with Node.js 20.x runtime
- Auto-zipped by Terraform with source change detection
- Formats AWS Health events for better readability

### Configuration Requirements
Each environment needs `terraform.tfvars` with:
- `aws_region`, `environment`, `github_org`, `github_repo`
- `owner_team`, `cost_center`
- `tags` object with mandatory Environment, Service, etc.

### Security
- Least privilege IAM roles for Lambda
- EventBridge-specific SNS publish permissions
- Resource groups for organization and compliance tracking