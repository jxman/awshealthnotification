# 🧪 Testing Scripts

This directory contains all testing scripts for the AWS Health Notification system.

## Available Scripts

### `test-health-notification.sh`
Tests the complete health notification workflow.
```bash
./test-health-notification.sh dev   # Test dev environment
./test-health-notification.sh prod  # Test prod environment
```

### `test-lambda-formatter.sh`
Tests the Lambda function message formatting.
```bash
./test-lambda-formatter.sh
```

### `test-deploy.sh`
Tests the deployment script functionality.
```bash
./test-deploy.sh
```

### `test-init.sh`
Tests the initialization script and GitHub Actions alignment.
```bash
./test-init.sh
```

## 🚀 Running Tests

All test scripts are executable and can be run directly:
```bash
cd scripts/testing
./test-health-notification.sh dev
```

Or from the root directory:
```bash
./scripts/testing/test-health-notification.sh dev
```
