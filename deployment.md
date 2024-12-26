# Deployment Guide

This guide explains how to deploy changes to development and production environments using our GitHub Actions CI/CD pipeline.

## Prerequisites

- GitHub repository access
- AWS credentials configured
- Required GitHub secrets set up
- Terraform installed locally (for testing)

## Environment Structure

```
environments/
├── dev/
│   ├── main.tf
│   └── variables.tf
└── prod/
    ├── main.tf
    └── variables.tf
```

## Deployment Process

### Development Environment

1. Create a new feature branch:

```bash
git checkout -b feature/dev-update
```

2. Make your changes to the appropriate files:

   - Modify files in `environments/dev/`
   - Update module configurations if needed
   - Test locally if possible

3. Commit and push changes:

```bash
git add .
git commit -m "feat(dev): Description of your changes"
git push origin feature/dev-update
```

4. Create Pull Request:

   - Go to GitHub repository
   - Create new Pull Request from your branch
   - Review the automated Terraform plan in PR comments
   - Get necessary approvals

5. Merge Pull Request:

   - GitHub Actions will automatically:
     - Run Terraform plan
     - Deploy to dev environment
     - No manual approval required for dev

6. Clean up:

```bash
git checkout main
git pull origin main
git branch -d feature/dev-update
git push origin --delete feature/dev-update
```

### Production Environment

1. Create a production feature branch:

```bash
git checkout -b feature/prod-update
```

2. Make your changes:

   - Modify files in `environments/prod/`
   - Ensure changes are production-ready
   - Consider impact on existing resources

3. Commit and push changes:

```bash
git add .
git commit -m "feat(prod): Description of your changes"
git push origin feature/prod-update
```

4. Create Pull Request:

   - Go to GitHub repository
   - Create new Pull Request from your branch
   - Review the automated Terraform plan carefully
   - Get required approvals

5. Merge Process:

   - After PR approval, merge to main
   - GitHub Actions will:
     - Run Terraform plan
     - Wait for manual approval in production environment
     - Apply changes after approval

6. Production Deployment:

   - Go to GitHub Actions
   - Review the workflow run
   - Approve deployment in production environment
   - Monitor the apply process

7. Clean up:

```bash
git checkout main
git pull origin main
git branch -d feature/prod-update
git push origin --delete feature/prod-update
```

## Best Practices

### General

- Always create feature branches from main
- Use meaningful commit messages
- Test changes locally when possible
- Review Terraform plans carefully

### Development

- Use dev environment for testing
- Keep dev environment similar to prod
- Test all changes in dev first

### Production

- Always get peer review
- Deploy during designated maintenance windows
- Have rollback plan ready
- Monitor resources after deployment

## Monitoring Deployments

1. GitHub Actions:

   - Watch the workflow progress
   - Review any error messages
   - Check plan output before apply

2. AWS Console:
   - Monitor resource creation/updates
   - Check CloudWatch logs
   - Verify SNS topics and subscriptions

## Troubleshooting

1. Failed Plan:

   - Check error messages in GitHub Actions logs
   - Verify AWS credentials
   - Check resource configurations

2. Failed Apply:

   - Review error messages
   - Check AWS service quotas
   - Verify IAM permissions

3. State Issues:
   - Check S3 bucket access
   - Verify DynamoDB table
   - Review state file locks

## Rolling Back Changes

If you need to roll back a deployment:

1. Find the last working state:

   - Check Terraform state history
   - Identify last known good configuration

2. Create rollback branch:

```bash
git checkout -b rollback/[env]-[description]
```

3. Revert to previous version:

   - Either revert commit or
   - Restore previous configuration

4. Follow normal deployment process for the environment

## Support

For issues or questions:

- Check GitHub Actions logs
- Review AWS CloudWatch logs
- Contact platform team for assistance

Remember: Production changes require more scrutiny and explicit approval. When in doubt, test in dev first!
