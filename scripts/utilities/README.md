# 🛠️ Utility Scripts

This directory contains utility and management scripts for the AWS Health Notification project.

## Available Scripts

### `setup-summary.sh`
Displays project status, configuration summary, and setup guide.
```bash
./setup-summary.sh
```

### `manage-logs.sh`
Interactive log management tool for deployment logs.
```bash
./manage-logs.sh
```

### `cleanup-project.sh`
Comprehensive project cleanup utility.
```bash
./cleanup-project.sh
```

### `quick-cleanup.sh`
Quick cleanup for temporary files.
```bash
./quick-cleanup.sh
```

## 🔗 Wrapper Scripts

The following wrapper scripts are available in the root directory for convenience:
- `setup-summary.sh` → `scripts/utilities/setup-summary.sh`
- `manage-logs.sh` → `scripts/utilities/manage-logs.sh`

## 🚀 Usage

Run utility scripts directly:
```bash
cd scripts/utilities
./setup-summary.sh
```

Or use wrapper scripts from root:
```bash
./setup-summary.sh  # Uses wrapper script
```
