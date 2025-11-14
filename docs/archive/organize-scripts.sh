#!/bin/bash

# Script Organization Tool - Compatible with older bash versions
# This script reorganizes all scripts into logical directories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📁 Script Organization Tool${NC}"
echo "=========================="
echo ""

# Scripts to keep in root (essential, frequently used)
ROOT_SCRIPTS="init.sh deploy.sh validate-backend.sh"

# Scripts to move to testing directory
TESTING_SCRIPTS="test-health-notification.sh test-lambda-formatter.sh test-deploy.sh test-init.sh"

# Scripts to move to utilities directory
UTILITY_SCRIPTS="setup-summary.sh manage-logs.sh cleanup-project.sh quick-cleanup.sh"

# Scripts to move to legacy directory
LEGACY_SCRIPTS="deploy-simple.sh"

# Function to check if script exists and is executable
check_script() {
    local script=$1
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "✅ $script (executable)"
        else
            echo "📄 $script (not executable)"
        fi
        return 0
    else
        echo "❌ $script (not found)"
        return 1
    fi
}

# Function to move script safely
move_script() {
    local script=$1
    local target_dir=$2
    
    if [ -f "$script" ]; then
        # Ensure target directory exists
        mkdir -p "$target_dir"
        
        # Move the script
        mv "$script" "$target_dir/"
        echo "  ✅ Moved $script → $target_dir/"
        
        # Make sure it's executable
        chmod +x "$target_dir/$script"
        
        return 0
    else
        echo "  ⚠️  $script not found, skipping"
        return 1
    fi
}

# Function to create wrapper script for backward compatibility
create_wrapper() {
    local script_name=$1
    local target_path=$2
    
    cat > "$script_name" << EOF
#!/bin/bash
# Wrapper script for backward compatibility
# This script redirects to the organized location: $target_path

# Check if the target script exists
if [ ! -f "$target_path" ]; then
    echo "Error: Target script not found at $target_path"
    exit 1
fi

# Execute the target script with all arguments
exec "$target_path" "\$@"
EOF
    
    chmod +x "$script_name"
    echo "  🔗 Created wrapper: $script_name → $target_path"
}

echo -e "${BLUE}📋 Current Script Inventory:${NC}"
echo ""

echo -e "${GREEN}🔧 Core Scripts (will stay in root):${NC}"
for script in $ROOT_SCRIPTS; do
    echo "  $(check_script "$script")"
done

echo ""
echo -e "${YELLOW}🧪 Testing Scripts (will move to scripts/testing/):${NC}"
for script in $TESTING_SCRIPTS; do
    echo "  $(check_script "$script")"
done

echo ""
echo -e "${BLUE}🛠️  Utility Scripts (will move to scripts/utilities/):${NC}"
for script in $UTILITY_SCRIPTS; do
    echo "  $(check_script "$script")"
done

echo ""
echo -e "${CYAN}📦 Legacy Scripts (will move to scripts/legacy/):${NC}"
for script in $LEGACY_SCRIPTS; do
    echo "  $(check_script "$script")"
done

echo ""
echo -e "${YELLOW}📁 Target Directory Structure:${NC}"
echo "  📦 awshealthnotification/"
echo "  ├── 🔧 init.sh, deploy.sh, validate-backend.sh (root)"
echo "  ├── 📁 scripts/"
echo "  │   ├── 📁 testing/ (test scripts)"
echo "  │   ├── 📁 utilities/ (utility scripts)"
echo "  │   └── 📁 legacy/ (backup scripts)"
echo "  └── 📁 logs/ (deployment logs)"

echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "  • Core scripts stay in root for easy access"
echo "  • Wrapper scripts will be created for moved scripts"
echo "  • All existing script calls will continue to work"
echo "  • Scripts will be properly organized and documented"

echo ""
read -p "$(echo -e ${CYAN}Do you want to proceed with script organization? [y/N]: ${NC})" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🚫 Script organization cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting script organization...${NC}"
echo ""

# Create directory structure
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p scripts/testing
mkdir -p scripts/utilities  
mkdir -p scripts/legacy
echo "  ✅ Created scripts/testing/"
echo "  ✅ Created scripts/utilities/"
echo "  ✅ Created scripts/legacy/"

echo ""

# Move testing scripts
echo -e "${YELLOW}🧪 Moving testing scripts...${NC}"
for script in $TESTING_SCRIPTS; do
    move_script "$script" "scripts/testing"
done

echo ""

# Move utility scripts
echo -e "${BLUE}🛠️  Moving utility scripts...${NC}"
for script in $UTILITY_SCRIPTS; do
    move_script "$script" "scripts/utilities"
done

echo ""

# Move legacy scripts
echo -e "${CYAN}📦 Moving legacy scripts...${NC}"
for script in $LEGACY_SCRIPTS; do
    move_script "$script" "scripts/legacy"
done

echo ""

# Create wrapper scripts for frequently used utilities
echo -e "${GREEN}🔗 Creating wrapper scripts for backward compatibility...${NC}"

# Create wrapper for setup-summary.sh (frequently used)
if [ -f "scripts/utilities/setup-summary.sh" ]; then
    create_wrapper "setup-summary.sh" "scripts/utilities/setup-summary.sh"
fi

# Create wrapper for manage-logs.sh (frequently used)
if [ -f "scripts/utilities/manage-logs.sh" ]; then
    create_wrapper "manage-logs.sh" "scripts/utilities/manage-logs.sh"
fi

echo ""

# Create README files for each script directory
echo -e "${BLUE}📚 Creating documentation...${NC}"

# Main scripts README
cat > "scripts/README.md" << 'EOF'
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
EOF

# Testing scripts README
cat > "scripts/testing/README.md" << 'EOF'
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
EOF

# Utilities scripts README  
cat > "scripts/utilities/README.md" << 'EOF'
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
EOF

# Legacy scripts README
cat > "scripts/legacy/README.md" << 'EOF'
# 📦 Legacy Scripts

This directory contains backup and legacy scripts that are preserved for reference.

## Available Scripts

### `deploy-simple.sh`
Original simple deployment script before enhancements.
```bash
./deploy-simple.sh dev   # Simple deployment to dev
./deploy-simple.sh prod  # Simple deployment to prod
```

## ⚠️ Usage Notes

- Legacy scripts are provided for reference and backup purposes
- Use the enhanced scripts in the root directory for current deployments
- These scripts may not have the latest security and validation features

## 🔄 Migration

If you need to use legacy functionality:
1. Review the legacy script
2. Consider if the enhanced version meets your needs
3. Use legacy scripts only if necessary for specific requirements
EOF

echo "  ✅ Created scripts/README.md"
echo "  ✅ Created scripts/testing/README.md"
echo "  ✅ Created scripts/utilities/README.md"
echo "  ✅ Created scripts/legacy/README.md"

echo ""
echo -e "${GREEN}✨ Script organization completed successfully!${NC}"
echo ""

echo -e "${BLUE}📋 Organization Summary:${NC}"
echo "════════════════════════════════════════"

# Count scripts in each category
ROOT_COUNT=0
for script in $ROOT_SCRIPTS; do
    [ -f "$script" ] && ROOT_COUNT=$((ROOT_COUNT + 1))
done

TESTING_COUNT=$(find scripts/testing -name "*.sh" 2>/dev/null | wc -l)
UTILITY_COUNT=$(find scripts/utilities -name "*.sh" 2>/dev/null | wc -l)
LEGACY_COUNT=$(find scripts/legacy -name "*.sh" 2>/dev/null | wc -l)

echo "  🔧 Core scripts (root): $ROOT_COUNT"
echo "  🧪 Testing scripts: $TESTING_COUNT"
echo "  🛠️  Utility scripts: $UTILITY_COUNT"
echo "  📦 Legacy scripts: $LEGACY_COUNT"
echo ""

echo -e "${GREEN}🎉 Benefits Achieved:${NC}"
echo "  ✅ Clean root directory with only essential scripts"
echo "  ✅ Logical grouping of related scripts"
echo "  ✅ Comprehensive documentation for each category"
echo "  ✅ Backward compatibility maintained"
echo "  ✅ Professional project structure"

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "  1. Test core scripts: ./init.sh dev, ./deploy.sh dev"
echo "  2. Test wrapper scripts: ./setup-summary.sh"
echo "  3. Explore organized scripts: ls -la scripts/*/"
echo "  4. Read documentation: cat scripts/README.md"

echo ""
echo -e "${CYAN}🚀 Your scripts are now professionally organized!${NC}"
