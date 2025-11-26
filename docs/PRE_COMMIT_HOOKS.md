# Pre-Commit Hooks Guide

This project uses [pre-commit](https://pre-commit.com/) to enforce code quality, security, and Terraform best practices before commits.

## What Are Pre-Commit Hooks?

Pre-commit hooks are automated checks that run **before** you commit code. They:
- ✅ Auto-format Terraform files
- ✅ Validate Terraform syntax
- ✅ Prevent credential leaks
- ✅ Enforce code quality standards
- ✅ Clean up whitespace and file endings

## Installed Hooks

### Terraform Hooks
| Hook | Description | Auto-Fix |
|------|-------------|----------|
| `terraform_fmt` | Formats Terraform files to canonical format | ✅ Yes |
| `terraform_validate` | Validates Terraform syntax and configuration | ❌ No |

### Security Hooks
| Hook | Description | Auto-Fix |
|------|-------------|----------|
| `detect-aws-credentials` | Detects AWS access keys in files | ❌ No (blocks commit) |
| `detect-private-key` | Detects private keys (SSH, PEM, etc.) | ❌ No (blocks commit) |
| `check-added-large-files` | Prevents files >500KB from being committed | ❌ No (blocks commit) |

### Code Quality Hooks
| Hook | Description | Auto-Fix |
|------|-------------|----------|
| `trailing-whitespace` | Removes trailing whitespace | ✅ Yes |
| `end-of-file-fixer` | Ensures files end with newline | ✅ Yes |
| `check-yaml` | Validates YAML syntax | ❌ No |
| `check-merge-conflict` | Detects merge conflict markers | ❌ No (blocks commit) |
| `check-case-conflict` | Detects case-sensitive filename conflicts | ❌ No (blocks commit) |

## Usage

### Automatic (Default Behavior)

Hooks run automatically when you commit:

```bash
git add .
git commit -m "your commit message"
# ✓ Pre-commit hooks run automatically
```

**Example output:**
```
Terraform format.........................................................Passed
Terraform validate.......................................................Passed
Trim trailing whitespace.................................................Passed
Fix end of files.........................................................Passed
Check YAML syntax........................................................Passed
Detect AWS credentials in files..........................................Passed
[main abc1234] your commit message
```

### Manual Execution

Run hooks manually without committing:

```bash
# Run on all files
pre-commit run --all-files

# Run on specific files
pre-commit run --files path/to/file.tf

# Run specific hook only
pre-commit run terraform_fmt --all-files
```

### Skip Hooks (Emergency Only)

**⚠️ NOT RECOMMENDED** - Skip hooks in emergency situations:

```bash
git commit --no-verify -m "emergency fix"
```

**When to skip:**
- Critical production hotfix
- You've already manually verified changes
- Hook is incorrectly failing (report as bug)

**Never skip for:**
- "I'm in a hurry"
- "I'll fix it later"
- Avoiding AWS credential detection

## What Happens When Hooks Fail?

### Auto-Fix Hooks (terraform_fmt, trailing-whitespace, end-of-file-fixer)

1. Hook modifies your files
2. Commit is **aborted**
3. Review the changes
4. Stage the auto-fixed files
5. Commit again

**Example:**
```bash
$ git commit -m "update terraform"
Terraform format.........................................................Failed
- hook id: terraform_fmt
- files were modified by this hook

Fixing environments/dev/main.tf

# Review the auto-formatted files
$ git diff

# Stage the fixes
$ git add environments/dev/main.tf

# Commit again
$ git commit -m "update terraform"
Terraform format.........................................................Passed
[main abc1234] update terraform
```

### Blocking Hooks (detect-aws-credentials, detect-private-key, etc.)

1. Hook detects an issue
2. Commit is **blocked**
3. Fix the issue manually
4. Stage and commit again

**Example - AWS Credentials Detected:**
```bash
$ git commit -m "add config"
Detect AWS credentials in files..........................................Failed
- hook id: detect-aws-credentials
- exit code: 1

config/settings.json:3:AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE

# Fix: Remove credentials or move to .env (which is .gitignored)
$ vim config/settings.json  # Remove credentials
$ git add config/settings.json
$ git commit -m "add config"
Detect AWS credentials in files..........................................Passed
[main abc1234] add config
```

## Common Scenarios

### Scenario 1: Terraform Formatting

```bash
# You modify Terraform files
$ vim environments/prod/main.tf

# Commit triggers auto-format
$ git commit -m "update prod config"
Terraform format.........................................................Failed
- files were modified by this hook
Fixing environments/prod/main.tf

# Stage auto-formatted files
$ git add environments/prod/main.tf

# Commit again (now passes)
$ git commit -m "update prod config"
Terraform format.........................................................Passed
✓ All checks passed!
```

### Scenario 2: Terraform Validation Error

```bash
# You have syntax error in Terraform
$ git commit -m "add new resource"
Terraform validate.......................................................Failed
- hook id: terraform_validate
- exit code: 1

Error: Invalid expression
  on environments/dev/main.tf line 25:
  25:   name = ${var.environment}-bucket

# Fix the error
$ vim environments/dev/main.tf
# Change to: name = "${var.environment}-bucket"

$ git add environments/dev/main.tf
$ git commit -m "add new resource"
Terraform validate.......................................................Passed
✓ Committed successfully
```

### Scenario 3: Accidentally Committing AWS Credentials

```bash
# You accidentally add credentials
$ git add config.json
$ git commit -m "update config"
Detect AWS credentials in files..........................................Failed
- hook id: detect-aws-credentials

config.json:5:aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# ✓ Commit blocked! Credentials NOT committed to git
# Fix: Remove credentials from file

$ vim config.json  # Remove credentials
$ git add config.json
$ git commit -m "update config"
Detect AWS credentials in files..........................................Passed
✓ Safe to commit
```

## Updating Hooks

Update to latest hook versions:

```bash
# Update hook repositories
pre-commit autoupdate

# Verify updates work
pre-commit run --all-files
```

## Troubleshooting

### Issue: "command not found: pre-commit"

**Solution:** Install pre-commit framework
```bash
# macOS (Homebrew)
brew install pre-commit

# Python (pip)
pip install pre-commit

# Verify installation
pre-commit --version
```

### Issue: Hooks not running on commit

**Solution:** Reinstall hooks
```bash
pre-commit install
```

### Issue: Hook failing incorrectly

**Solution 1:** Update hooks
```bash
pre-commit autoupdate
pre-commit run --all-files
```

**Solution 2:** Clear cache and reinstall
```bash
pre-commit clean
pre-commit install --install-hooks
pre-commit run --all-files
```

### Issue: "terraform: command not found"

**Solution:** Ensure Terraform is installed and in PATH
```bash
# Check Terraform installation
terraform version

# If not installed, install Terraform
brew install terraform  # macOS
```

## Best Practices

### ✅ Do This

- Run `pre-commit run --all-files` after pulling changes
- Review auto-fixed changes before committing
- Update hooks regularly with `pre-commit autoupdate`
- Report hook issues to the team
- Keep credentials in environment variables or `.env` files

### ❌ Avoid This

- Don't use `--no-verify` unless absolutely necessary
- Don't commit credentials "temporarily"
- Don't ignore hook failures without investigating
- Don't disable hooks locally without team discussion
- Don't commit large binary files (>500KB)

## Adding More Hooks

Want to add security scanning or documentation generation?

See the enhanced configuration options in the project documentation or contact the team lead.

**Available enhanced hooks:**
- `terraform_tfsec` - Security scanning for Terraform
- `terraform_tflint` - Advanced linting and best practices
- `terraform_docs` - Auto-generate module documentation

## Resources

- **Pre-commit Framework:** https://pre-commit.com/
- **Pre-commit Terraform Hooks:** https://github.com/antonbabenko/pre-commit-terraform
- **Configuration File:** `.pre-commit-config.yaml`

## Questions?

Check the team wiki or ask in the engineering Slack channel.

---

**Last Updated:** 2025-11-26
**Maintained By:** Platform Team
