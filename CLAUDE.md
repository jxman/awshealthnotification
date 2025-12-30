# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a **Terraform-managed AWS Health Notifications Infrastructure** that automates AWS Health Event notifications using:
- **EventBridge** - Captures and filters AWS Health events
- **Lambda** (Node.js 22.x) - Formats notifications with enhanced readability
- **SNS** - Manages notification distribution to subscribers
- **S3 backend** with native locking for state management
- **GitHub Actions CI/CD** - Automated deployment pipeline (REQUIRED)

### Event Flow
```
AWS Health Events → EventBridge → Lambda Function → SNS Topic → Email/SMS
```

### Environment Structure
- `environments/dev/` - Development environment config
- `environments/prod/` - Production environment config
- `modules/` - Reusable Terraform modules (eventbridge, sns, resource_groups)
- `backend/` - S3 backend configurations (*.hcl files)
- `.github/workflows/terraform.yml` - CI/CD pipeline configuration

## ⚠️ CRITICAL DEPLOYMENT POLICY

**NEVER suggest or run `terraform apply` commands locally.**

**ALL deployments MUST be done via GitHub Actions CI/CD pipeline.**

### Deployment Instructions for Claude

When the user asks to deploy changes:

1. ❌ **NEVER suggest**: `./deploy.sh`, `terraform apply`, or any local deployment commands
2. ✅ **ALWAYS suggest**: Creating a PR and merging to main for GitHub Actions deployment
3. ✅ **ALLOWED**: Local `terraform plan` for validation (read-only)
4. ✅ **ALLOWED**: Local `terraform init` and `terraform validate` for testing

### Correct Deployment Process

**For Development**:
```bash
# Create feature branch
git checkout -b feature/description

# Make changes to code/configs
# Test locally with plan (optional)
cd environments/dev
terraform init -backend-config=../../backend/dev.hcl
terraform plan -var-file="terraform.tfvars"

# Commit and push
git add .
git commit -m "feat: description"
git push origin feature/description

# Create PR → Merge to main → GitHub Actions auto-deploys to dev
```

**For Production**:
```bash
# Follow same PR process
# Then: GitHub Actions → Run workflow → Select 'prod' → Approve deployment
```

## Common Commands (Read-Only)

### Local Validation (SAFE)
```bash
# Initialize Terraform (read-only)
cd environments/dev
terraform init -backend-config=../../backend/dev.hcl

# Validate configuration
terraform validate

# Plan changes (does NOT apply)
terraform plan -var-file="terraform.tfvars"
```

### ❌ PROHIBITED Commands
```bash
# NEVER run these locally:
terraform apply
./deploy.sh
./init.sh && terraform apply
```

### Testing & Verification
```bash
# Test Lambda function locally
node -c modules/eventbridge/lambda/index.js

# View deployment logs in GitHub Actions
# Go to: Repository → Actions → Select workflow run
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
- Uses AWS SDK v3 with Node.js 22.x runtime
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
