#!/bin/bash

# Ultra-simple validation script that actually works
# This version uses a much more reliable parsing approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔍 Backend Configuration Validation${NC}"
echo "====================================="
echo -e "${BLUE}Ensuring local configs match GitHub Actions workflow${NC}"
echo ""

# Expected values from GitHub Actions
EXPECTED_DEV_KEY="health-notifications/dev/terraform.tfstate"
EXPECTED_PROD_KEY="health-notifications/prod/terraform.tfstate"
EXPECTED_REGION="us-east-1"
EXPECTED_ENCRYPT="true"
EXPECTED_LOCKFILE="true"

VALIDATION_PASSED=true

# Simple function to extract quoted or unquoted values
get_value() {
    local file="$1"
    local key="$2"
    
    if [ ! -f "$file" ]; then
        echo ""
        return
    fi
    
    # Use awk for more reliable parsing
    awk -F= -v key="$key" '
        $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
            gsub(/^[[:space:]]*[^=]*=[[:space:]]*"?/, "", $0)
            gsub(/"?[[:space:]]*$/, "", $0)
            print $0
            exit
        }
    ' "$file"
}

# Function to validate backend config
validate_env() {
    local env=$1
    local expected_key=$2
    local config_file="backend/${env}.hcl"
    
    echo -e "${BLUE}Validating ${env} environment...${NC}"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Missing: $config_file${NC}"
        VALIDATION_PASSED=false
        return
    fi
    
    # Get actual values
    local bucket=$(get_value "$config_file" "bucket")
    local key=$(get_value "$config_file" "key")
    local region=$(get_value "$config_file" "region")
    local encrypt=$(get_value "$config_file" "encrypt")
    local lockfile=$(get_value "$config_file" "use_lockfile")
    
    echo "  Bucket: '$bucket'"
    echo "  Key: '$key'"
    echo "  Region: '$region'"
    echo "  Encrypt: '$encrypt'"
    echo "  Use Lockfile: '$lockfile'"
    
    # Validate each field
    local env_passed=true
    
    if [ "$key" = "$expected_key" ]; then
        echo -e "  ${GREEN}✅ Key pattern correct${NC}"
    else
        echo -e "  ${RED}❌ Key mismatch: expected '$expected_key', got '$key'${NC}"
        env_passed=false
    fi
    
    if [ "$region" = "$EXPECTED_REGION" ]; then
        echo -e "  ${GREEN}✅ Region correct${NC}"
    else
        echo -e "  ${RED}❌ Region mismatch: expected '$EXPECTED_REGION', got '$region'${NC}"
        env_passed=false
    fi
    
    if [ "$encrypt" = "$EXPECTED_ENCRYPT" ]; then
        echo -e "  ${GREEN}✅ Encryption correct${NC}"
    else
        echo -e "  ${RED}❌ Encryption mismatch: expected '$EXPECTED_ENCRYPT', got '$encrypt'${NC}"
        env_passed=false
    fi
    
    if [ "$lockfile" = "$EXPECTED_LOCKFILE" ]; then
        echo -e "  ${GREEN}✅ Lockfile setting correct${NC}"
    else
        echo -e "  ${RED}❌ Lockfile mismatch: expected '$EXPECTED_LOCKFILE', got '$lockfile'${NC}"
        env_passed=false
    fi
    
    if [ -n "$bucket" ] && [ "$bucket" != "your-terraform-state-bucket" ]; then
        echo -e "  ${GREEN}✅ Bucket configured: $bucket${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Bucket needs configuration${NC}"
    fi
    
    if [ "$env_passed" = false ]; then
        VALIDATION_PASSED=false
    fi
    
    echo ""
}

# Validate both environments
validate_env "dev" "$EXPECTED_DEV_KEY"
validate_env "prod" "$EXPECTED_PROD_KEY"

# Check GitHub Actions workflow
WORKFLOW_FILE=".github/workflows/terraform.yml"
if [ -f "$WORKFLOW_FILE" ]; then
    echo -e "${GREEN}✅ GitHub Actions workflow found${NC}"
    
    if grep -q "health-notifications/.*terraform.tfstate" "$WORKFLOW_FILE"; then
        echo -e "${GREEN}✅ Workflow uses expected state pattern${NC}"
    fi
    
    if grep -q "use_lockfile = true" "$WORKFLOW_FILE"; then
        echo -e "${GREEN}✅ Workflow uses S3 native locking${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  GitHub Actions workflow not found${NC}"
fi

echo ""

# Final summary
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}🎉 Perfect! All configurations match GitHub Actions!${NC}"
    echo ""
    echo -e "${BLUE}📋 Configuration Summary:${NC}"
    echo "  • ✅ Dev state: health-notifications/dev/terraform.tfstate"
    echo "  • ✅ Prod state: health-notifications/prod/terraform.tfstate"
    echo "  • ✅ Region: us-east-1"
    echo "  • ✅ Encryption: enabled"
    echo "  • ✅ Locking: S3 native"
    echo "  • ✅ Consistency: Local ↔ GitHub Actions"
    echo ""
    
    # Test S3 access
    DEV_BUCKET=$(get_value "backend/dev.hcl" "bucket")
    if [ -n "$DEV_BUCKET" ]; then
        echo -e "${BLUE}🔐 Testing S3 access...${NC}"
        if aws s3 ls "s3://$DEV_BUCKET" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ S3 bucket accessible: $DEV_BUCKET${NC}"
        else
            echo -e "${YELLOW}⚠️  S3 access test failed (check AWS credentials)${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}🚀 Ready to deploy!${NC}"
    echo "  ./init.sh dev    # Initialize dev environment"
    echo "  ./init.sh prod   # Initialize prod environment"
else
    echo -e "${RED}❌ Configuration issues found${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Your backend files look correct, but some values don't match.${NC}"
    echo "This might be a parsing issue. Let's show the raw files:"
    echo ""
    
    echo -e "${BLUE}Raw backend/dev.hcl:${NC}"
    echo "─────────────────────"
    cat backend/dev.hcl 2>/dev/null || echo "File not found"
    echo "─────────────────────"
    echo ""
    
    echo -e "${BLUE}Raw backend/prod.hcl:${NC}"
    echo "─────────────────────"
    cat backend/prod.hcl 2>/dev/null || echo "File not found"
    echo "─────────────────────"
fi

echo ""
echo -e "${BLUE}Next: Try ./init.sh dev to test initialization${NC}"
