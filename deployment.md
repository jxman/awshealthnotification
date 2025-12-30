# Deployment Guide

## ⚠️ CRITICAL DEPLOYMENT POLICY

**ALL deployments MUST be done through GitHub Actions CI/CD pipeline.**

**Local Terraform deployments (`terraform apply`) are STRICTLY PROHIBITED.**

### Why GitHub Actions Only?

- **State Management**: Prevents state conflicts and corruption
- **Consistency**: Ensures identical deployment process for all changes
- **Audit Trail**: Full history of who deployed what and when
- **Approval Gates**: Production deployments require explicit approval
- **Security**: AWS credentials managed securely via GitHub Secrets
- **Validation**: Automated Lambda validation before deployment

### Consequences of Local Deployments

❌ **DO NOT run `terraform apply` locally** - This will:
- Create state lock conflicts with GitHub Actions
- Use different tfvars configurations than CI/CD
- Bypass approval requirements for production
- Break the deployment audit trail
- Potentially cause resource drift

✅ **Local `terraform plan` is allowed** for validation before pushing

## Prerequisites

- GitHub repository access with write permissions
- Required GitHub secrets configured (see below)
- Appropriate environment permissions (dev: auto, prod: manual approval)

## Required GitHub Secrets

Configure these secrets in **Settings → Secrets and variables → Actions**:

| Secret Name             | Description                  | Example                   |
| ----------------------- | ---------------------------- | ------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS Access Key for deployments | `AKIA...`                |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key        | `xxxx...`                 |
| `TF_STATE_BUCKET`       | S3 bucket for Terraform state | `my-terraform-state-123` |

## GitHub Environments

Configure in **Settings → Environments**:

### Development Environment (`dev`)
- **Protection Rules**: None
- **Deployment Branches**: `main` only
- **Auto-Deploy**: ✅ Yes (on merge to main)

### Production Environment (`prod`)
- **Protection Rules**: Required reviewers (1+ approvers)
- **Deployment Branches**: `main` only
- **Auto-Deploy**: ❌ No (manual workflow dispatch only)

## Environment Structure

```
environments/
├── dev/
│   ├── main.tf              # EventBridge enabled = false (disabled by default)
│   ├── variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf              # EventBridge enabled = true (always active)
    ├── variables.tf
    └── terraform.tfvars
```

## Environment-Specific Notification Control

Each environment can independently control AWS Health notifications:

- **Development**: EventBridge disabled by default to prevent duplicate alerts
- **Production**: EventBridge always enabled for critical monitoring

To enable dev notifications temporarily (e.g., for testing):
1. Edit `environments/dev/main.tf`
2. Change `enabled = false` to `enabled = true` in the eventbridge module
3. Deploy via GitHub Actions (create PR → merge)
4. Remember to disable again after testing

## Deployment Workflows

### Development Deployment (Automatic)

**Trigger**: Merge to `main` branch

**Process**:

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**:
   - Modify files in `environments/dev/` or `modules/`
   - Test locally with `terraform plan` if needed (optional)

3. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat(dev): description of changes"
   git push origin feature/your-feature-name
   ```

4. **Create Pull Request**:
   - Go to GitHub repository
   - Click "Pull requests" → "New pull request"
   - Select your feature branch
   - Review automated Terraform plan in PR checks
   - Request reviews if needed

5. **Merge Pull Request**:
   - Once approved, merge to `main`
   - **GitHub Actions automatically**:
     - ✅ Validates Lambda function syntax
     - ✅ Runs `terraform plan`
     - ✅ Applies changes to dev environment
     - ✅ No manual approval required

6. **Verify Deployment**:
   - Go to **Actions** tab → View workflow run
   - Check deployment logs
   - Verify resources in AWS Console

7. **Clean Up Branch**:
   ```bash
   git checkout main
   git pull origin main
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

### Production Deployment (Manual Approval Required)

**Trigger**: Manual workflow dispatch

**Process**:

1. **Create Production Feature Branch**:
   ```bash
   git checkout -b feature/prod-your-feature
   ```

2. **Make Changes**:
   - Modify files in `environments/prod/`
   - **Ensure changes are production-ready**
   - Consider impact on existing resources

3. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat(prod): description of changes"
   git push origin feature/prod-your-feature
   ```

4. **Create Pull Request**:
   - Go to GitHub repository
   - Create new Pull Request
   - **Review Terraform plan output carefully**
   - Get required approvals from team

5. **Merge to Main**:
   - Merge PR to `main` branch
   - ⚠️ **This does NOT auto-deploy to prod**

6. **Manual Workflow Dispatch**:
   - Go to **Actions** → "Terraform CI/CD" workflow
   - Click **"Run workflow"** button
   - Select **environment**: `prod`
   - Click **"Run workflow"**

7. **Approve Production Deployment**:
   - GitHub Actions will:
     - ✅ Validate Lambda function
     - ✅ Run `terraform plan`
     - ⏸️ **PAUSE for manual approval**
   - Review the plan output
   - Click **"Review deployments"**
   - Select `prod` environment
   - Click **"Approve and deploy"**

8. **Monitor Deployment**:
   - Watch the apply job in real-time
   - Check for any errors
   - Verify resources in AWS Console

9. **Clean Up Branch**:
   ```bash
   git checkout main
   git pull origin main
   git branch -d feature/prod-your-feature
   git push origin --delete feature/prod-your-feature
   ```

## CI/CD Pipeline Details

### Workflow Stages

**Stage 1: Validate Lambda**
- Syntax check on Lambda function code
- Verify AWS SDK v3 imports
- Check for excessive debug logging
- Validate handler exports

**Stage 2: Terraform Plan**
- Initialize Terraform with S3 backend
- Generate execution plan
- Upload plan artifact for apply stage
- Package Lambda function ZIP

**Stage 3: Terraform Apply** (only on push to main or manual dispatch)
- Download plan artifact
- Apply changes to AWS infrastructure
- Production requires manual approval gate

### Workflow Triggers

| Trigger            | Dev Deployment | Prod Deployment |
| ------------------ | -------------- | --------------- |
| PR to `main`       | Plan only      | Plan only       |
| Merge to `main`    | ✅ Auto-apply   | ❌ No apply      |
| Workflow dispatch  | ✅ Optional     | ✅ With approval |

## Local Testing (Plan Only)

You may test Terraform locally **without applying changes**:

```bash
# Navigate to environment
cd environments/dev  # or prod

# Initialize (read-only, safe)
terraform init -backend-config=../../backend/dev.hcl

# Validate configuration
terraform validate

# Run plan (safe - shows what would change)
terraform plan -var-file="terraform.tfvars"

# ❌ NEVER RUN: terraform apply
```

## Monitoring Deployments

### GitHub Actions Dashboard

1. Go to **Actions** tab
2. Select workflow run
3. Review each job:
   - Validate Lambda ✅
   - Terraform Plan 📋
   - Terraform Apply 🚀

### AWS Console Verification

After deployment, verify in AWS Console:

1. **Lambda Functions**:
   - Check runtime updated (Node.js 22)
   - Verify environment variables
   - Review CloudWatch Logs

2. **EventBridge Rules**:
   - Verify rule state (ENABLED/DISABLED)
   - Check event pattern
   - Confirm Lambda target

3. **SNS Topics**:
   - Verify topic exists
   - Check subscriptions
   - Test publish permissions

4. **CloudWatch Logs**:
   - Check log groups created
   - Review recent Lambda executions
   - Monitor for errors

## Troubleshooting

### Failed Validation Stage

**Symptoms**: Lambda validation fails

**Solutions**:
- Check Lambda syntax: `node -c modules/eventbridge/lambda/index.js`
- Verify AWS SDK imports are present
- Ensure `exports.handler` is defined

### Failed Plan Stage

**Symptoms**: Terraform plan fails

**Solutions**:
- Check AWS credentials are configured
- Verify S3 backend bucket exists
- Review Terraform configuration syntax
- Check for resource naming conflicts

### Failed Apply Stage

**Symptoms**: Terraform apply fails

**Solutions**:
- Review error messages in workflow logs
- Check AWS service quotas
- Verify IAM permissions are sufficient
- Look for resource conflicts

### State Lock Errors

**Symptoms**: "Error acquiring state lock"

**Cause**: Another workflow is running or previous workflow didn't clean up

**Solution**:
- Wait for other workflows to complete
- Check GitHub Actions for running workflows
- If stuck, manually remove lock file from S3 bucket (last resort)

### No Notifications Received

**Symptoms**: AWS Health events not triggering notifications

**Debug Steps**:
1. Check EventBridge rule state:
   ```bash
   aws events describe-rule \
     --name "dev-health-event-notifications" \
     --region us-east-1 \
     --query '{Name:Name, State:State}'
   ```

2. Verify environment configuration:
   - Check if `enabled = false` in `main.tf`
   - Dev is disabled by default

3. Review Lambda logs:
   ```bash
   aws logs tail /aws/lambda/dev-health-event-formatter --follow
   ```

4. Confirm SNS subscriptions are active

## Rolling Back Changes

If you need to rollback a deployment:

### Option 1: Revert Commit

```bash
# Create rollback branch
git checkout -b rollback/description

# Revert the bad commit
git revert <commit-sha>

# Push and create PR
git push origin rollback/description

# Merge PR to trigger deployment
```

### Option 2: Restore Previous Configuration

```bash
# Create rollback branch
git checkout -b rollback/description

# Restore previous version of files
git checkout <previous-commit-sha> -- environments/dev/

# Commit restore
git commit -m "fix: rollback to previous configuration"

# Push and create PR
git push origin rollback/description

# Merge PR to trigger deployment
```

## Best Practices

### General

- ✅ Always create feature branches from `main`
- ✅ Use meaningful commit messages (conventional commits)
- ✅ Review Terraform plans carefully before approving
- ✅ Test changes in `dev` before deploying to `prod`
- ✅ Keep environment configurations in sync where appropriate
- ❌ Never run `terraform apply` locally
- ❌ Never commit AWS credentials to repository
- ❌ Never bypass approval gates for production

### Development

- Use dev environment for testing and experimentation
- Keep dev environment similar to prod (same modules, different variables)
- Test all changes in dev first before production
- Disable EventBridge in dev to prevent alert fatigue

### Production

- Always get peer review before merging
- Deploy during designated maintenance windows
- Have rollback plan ready before deployment
- Monitor resources closely after deployment
- Keep production EventBridge enabled
- Document all production changes

### Security

- Rotate AWS credentials regularly
- Use least-privilege IAM policies
- Enable S3 bucket encryption for state files
- Review CloudTrail logs for audit compliance
- Never share GitHub secrets

## Support

### Getting Help

- **Documentation**: Check this guide and [README.md](README.md)
- **GitHub Issues**: Report bugs and request features
- **AWS Console**: Review CloudWatch logs and metrics
- **Team**: Contact Platform Team for deployment issues

### Common Questions

**Q: Can I deploy directly from my machine?**
A: No. All deployments must go through GitHub Actions.

**Q: Why does dev deploy automatically but not prod?**
A: Dev has no approval gates for faster iteration. Production requires manual approval for safety.

**Q: How do I test changes before deploying?**
A: Use `terraform plan` locally, or review the plan output in GitHub Actions PR checks.

**Q: Can I skip the approval for production?**
A: No. Production approval gates are mandatory and cannot be bypassed.

**Q: What if I need to deploy urgently?**
A: Follow the same process. The approval can be done quickly if needed, but the process ensures safety.

---

**Remember**: Production deployments require careful review and explicit approval. When in doubt, ask for help!
