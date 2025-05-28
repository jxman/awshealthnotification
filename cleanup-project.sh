#!/bin/bash

# AWS Health Notification Terraform Project Cleanup Script
# This script identifies and removes unnecessary files to clean up the repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧹 AWS Health Notification Project Cleanup${NC}"
echo "=============================================="
echo ""

# Initialize arrays for different types of files
GENERATED_FILES=()
BACKUP_FILES=()
TEMP_FILES=()
OLD_SCRIPTS=()
LOG_FILES=()

# Function to add file to array if it exists
add_if_exists() {
    local file="$1"
    local array_name="$2"
    
    if [ -f "$file" ] || [ -d "$file" ]; then
        case $array_name in
            "generated") GENERATED_FILES+=("$file") ;;
            "backup") BACKUP_FILES+=("$file") ;;
            "temp") TEMP_FILES+=("$file") ;;
            "scripts") OLD_SCRIPTS+=("$file") ;;
            "logs") LOG_FILES+=("$file") ;;
        esac
    fi
}

echo -e "${BLUE}🔍 Scanning for files to cleanup...${NC}"

# Generated Terraform files that can be recreated
add_if_exists "environments/dev/.terraform" "generated"
add_if_exists "environments/prod/.terraform" "generated"
add_if_exists "modules/eventbridge/lambda_function.zip" "generated"

# Terraform state backup files (old versions)
add_if_exists "environments/dev/.terraform/terraform.tfstate.backup.1748435630" "backup"
add_if_exists "environments/dev/.terraform/terraform.tfstate.backup.1748435768" "backup"
add_if_exists "environments/dev/.terraform/terraform.tfstate.backup.1748453295" "backup"
add_if_exists "environments/prod/.terraform/terraform.tfstate.backup.1748453300" "backup"
add_if_exists "environments/dev/.terraform.lock.hcl" "generated"
add_if_exists "environments/prod/.terraform.lock.hcl" "generated"

# Temporary and log files
add_if_exists "environments/dev/plan1.log" "logs"
add_if_exists "environments/dev/plan2.log" "logs"

# Old/experimental scripts that appear to be one-time use
add_if_exists "cleanup-old-files.sh" "scripts"
add_if_exists "investigate-s3-locking.sh" "scripts"
add_if_exists "quick-lock-test.sh" "scripts"
add_if_exists "reinit-s3-native-locking.sh" "scripts"
add_if_exists "test-s3-locking.sh" "scripts"
add_if_exists "test-s3-native-locking.sh" "scripts"
add_if_exists "test-syntax.sh" "scripts"
add_if_exists "test-terraform-lambda-deploy.sh" "scripts"

# Test files that seem experimental
add_if_exists "test-event.json" "temp"
add_if_exists "test-health-enhanced.sh" "scripts"
add_if_exists "test-health-scenarios.sh" "scripts"

echo ""

# Function to display file list
display_files() {
    local title="$1"
    local color="$2"
    local category="$3"
    
    # Create a temporary array based on category
    local files_to_show=()
    case $category in
        "generated")
            files_to_show=("${GENERATED_FILES[@]}")
            ;;
        "backup")
            files_to_show=("${BACKUP_FILES[@]}")
            ;;
        "temp")
            files_to_show=("${TEMP_FILES[@]}")
            ;;
        "scripts")
            files_to_show=("${OLD_SCRIPTS[@]}")
            ;;
        "logs")
            files_to_show=("${LOG_FILES[@]}")
            ;;
    esac
    
    if [ ${#files_to_show[@]} -gt 0 ]; then
        echo -e "${color}${title}${NC}"
        for file in "${files_to_show[@]}"; do
            if [ -f "$file" ]; then
                SIZE=$(du -h "$file" 2>/dev/null | cut -f1)
                echo "  📄 $file ($SIZE)"
            elif [ -d "$file" ]; then
                SIZE=$(du -sh "$file" 2>/dev/null | cut -f1)
                echo "  📁 $file/ ($SIZE)"
            fi
        done
        echo ""
    fi
}

# Display categorized files
display_files "🔧 Generated Files (can be recreated with terraform init):" "$YELLOW" "generated"
display_files "💾 Backup Files (old terraform state backups):" "$BLUE" "backup"
display_files "📝 Log Files (temporary terraform plan logs):" "$BLUE" "logs"
display_files "🧪 Experimental/Old Scripts:" "$YELLOW" "scripts"
display_files "🗑️  Temporary Files:" "$YELLOW" "temp"

# Calculate total files
TOTAL_FILES=$((${#GENERATED_FILES[@]} + ${#BACKUP_FILES[@]} + ${#TEMP_FILES[@]} + ${#OLD_SCRIPTS[@]} + ${#LOG_FILES[@]}))

if [ $TOTAL_FILES -eq 0 ]; then
    echo -e "${GREEN}✨ No cleanup needed! Your project is already clean.${NC}"
    exit 0
fi

echo -e "${YELLOW}📊 Summary:${NC}"
echo "  • Generated files: ${#GENERATED_FILES[@]}"
echo "  • Backup files: ${#BACKUP_FILES[@]}"
echo "  • Log files: ${#LOG_FILES[@]}"
echo "  • Old scripts: ${#OLD_SCRIPTS[@]}"
echo "  • Temporary files: ${#TEMP_FILES[@]}"
echo "  • Total files to remove: $TOTAL_FILES"
echo ""

# Calculate total size
TOTAL_SIZE=0
for file in "${GENERATED_FILES[@]}" "${BACKUP_FILES[@]}" "${TEMP_FILES[@]}" "${OLD_SCRIPTS[@]}" "${LOG_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        SIZE_KB=$(du -k "$file" 2>/dev/null | cut -f1)
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE_KB))
    fi
done

TOTAL_SIZE_MB=$((TOTAL_SIZE / 1024))

echo -e "${BLUE}💾 Total space to be freed: ${TOTAL_SIZE_MB}MB${NC}"
echo ""

echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "  • Generated files (.terraform/, .lock.hcl) will be recreated on next 'terraform init'"
echo "  • State backup files are safe to remove (current state is preserved)"
echo "  • Keep test-health-notification.sh and test-lambda-formatter.sh (useful for testing)"
echo "  • Keep deploy.sh and init.sh (essential deployment scripts)"
echo ""

# Confirmation prompt
read -p "$(echo -e ${RED}❓ Do you want to proceed with the cleanup? [y/N]: ${NC})" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🚫 Cleanup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}🧹 Starting cleanup...${NC}"

# Function to safely remove files/directories
safe_remove() {
    local item="$1"
    local category="$2"
    
    if [ -f "$item" ]; then
        rm "$item" && echo -e "  ${GREEN}✓${NC} Removed file: $item"
    elif [ -d "$item" ]; then
        rm -rf "$item" && echo -e "  ${GREEN}✓${NC} Removed directory: $item/"
    else
        echo -e "  ${YELLOW}⚠${NC} Not found: $item"
    fi
}

# Remove files by category
if [ ${#GENERATED_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Removing generated files...${NC}"
    for file in "${GENERATED_FILES[@]}"; do
        safe_remove "$file" "generated"
    done
    echo ""
fi

if [ ${#BACKUP_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Removing backup files...${NC}"
    for file in "${BACKUP_FILES[@]}"; do
        safe_remove "$file" "backup"
    done
    echo ""
fi

if [ ${#LOG_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Removing log files...${NC}"
    for file in "${LOG_FILES[@]}"; do
        safe_remove "$file" "logs"
    done
    echo ""
fi

if [ ${#OLD_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Removing old scripts...${NC}"
    for file in "${OLD_SCRIPTS[@]}"; do
        safe_remove "$file" "scripts"
    done
    echo ""
fi

if [ ${#TEMP_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Removing temporary files...${NC}"
    for file in "${TEMP_FILES[@]}"; do
        safe_remove "$file" "temp"
    done
    echo ""
fi

echo -e "${GREEN}✨ Cleanup completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "  1. Run 'terraform init' in environments/dev/ and environments/prod/ when needed"
echo "  2. Review the updated README.md"
echo "  3. Commit the cleaned repository"
echo ""
echo -e "${GREEN}🎉 Your Terraform project is now clean and organized!${NC}"
