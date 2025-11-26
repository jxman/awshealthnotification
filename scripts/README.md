# 📁 Scripts Directory

This directory contains organized scripts for the AWS Health Notification project.

## 📂 Directory Structure

### 🧪 `testing/`
Scripts for testing various components of the system:
- `test-health-notification.sh` - Test health event notifications
- `test-lambda-formatter.sh` - Test Lambda function formatting
- `test-deploy.sh` - Test deployment script functionality
- `test-init.sh` - Test initialization script

### 🛠️ `utilities/`
Utility and management scripts:
- `setup-summary.sh` - Project status and setup guide
- `manage-logs.sh` - Log file management and cleanup
- `cleanup-project.sh` - Project cleanup utility
- `quick-cleanup.sh` - Quick cleanup for temporary files

### 📦 `legacy/`
Backup and legacy scripts:
- `deploy-simple.sh` - Original simple deployment script

## 🚀 Usage

### Direct Execution
```bash
# Run testing scripts
./scripts/testing/test-health-notification.sh dev

# Run utility scripts
./scripts/utilities/setup-summary.sh

# Access legacy scripts
./scripts/legacy/deploy-simple.sh dev
```

### Using Wrapper Scripts (Root Level)
```bash
# These still work from root directory
./setup-summary.sh      # Redirects to scripts/utilities/setup-summary.sh
./manage-logs.sh        # Redirects to scripts/utilities/manage-logs.sh
```

## 📋 Core Scripts (Root Level)

Essential scripts remain in the root directory for easy access:
- `init.sh` - Environment initialization
- `deploy.sh` - Main deployment script
- `validate-backend.sh` - Configuration validation

## 🔄 Backward Compatibility

All existing script calls continue to work through wrapper scripts that redirect to the new organized locations.
