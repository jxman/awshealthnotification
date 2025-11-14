#!/bin/bash

# AWS Health Notification - Setup Summary and Quick Start Guide
# This script shows you what's been configured and how to get started

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to extract value from HCL file
extract_value() {
    local file="$1"
    local key="$2"
    
    # Extract the value, handling both quoted and unquoted values
    if [ -f "$file" ]; then
        grep "^[[:space:]]*${key}[[:space:]]*=" "$file" | \
        sed 's/^[[:space:]]*[^=]*=[[:space:]]*"\?\([^"]*\)"\?[[:space:]]*$/\1/' | \
        head -1
    fi
}

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                🚀 AWS Health Notification Setup                 ║${NC}"
echo -e "${CYAN}║                   Complete & GitHub Actions Aligned             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ CONFIGURATION COMPLETED${NC}"
echo "========================="
echo ""

echo -e "${BLUE}🎯 What's Been Fixed & Enhanced:${NC}"
echo "  • Backend configurations now match GitHub Actions workflow exactly"
echo "  • Both dev and prod use the same S3 bucket (consistent with CI/CD)"  
echo "  • State keys follow GitHub pattern: health-notifications/{env}/terraform.tfstate"
echo "  • S3 native locking enabled (use_lockfile = true)"
echo "  • Enhanced init.sh with validation and GitHub Actions alignment"
echo "  • Added comprehensive validation and testing tools"
echo "  • Updated documentation and cleanup utilities"
echo ""

# Get bucket name from actual config
BUCKET_NAME=$(extract_value "backend/dev.hcl" "bucket")
if [ -z "$BUCKET_NAME" ]; then
    BUCKET_NAME="jxman-terraform-state-bucket"  # fallback
fi

echo -e "${BLUE}📋 Current Backend Configuration:${NC}"
echo "  • Dev State:  health-notifications/dev/terraform.tfstate"
echo "  • Prod State: health-notifications/prod/terraform.tfstate"
echo "  • Region:     us-east-1"
echo "  • Bucket:     $BUCKET_NAME"
echo "  • Locking:    S3 Native (use_lockfile = true)"
echo "  • Encryption: Enabled"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT: Before You Start${NC}"
echo "================================="
echo ""
echo -e "${YELLOW}1. GitHub Secret Configuration:${NC}"
echo "   Ensure your GitHub repository has this secret:"
echo "   • TF_STATE_BUCKET = \"$BUCKET_NAME\""
echo ""
echo -e "${YELLOW}2. S3 Bucket Verification:${NC}"
echo "   Make sure the S3 bucket exists and you have access:"
echo "   • Bucket: $BUCKET_NAME"
echo "   • Test: aws s3 ls s3://$BUCKET_NAME"
echo ""
echo -e "${YELLOW}3. AWS Credentials:${NC}"
echo "   Ensure your AWS credentials are configured:"
echo "   • Run: aws configure list"
echo "   • Verify: aws sts get-caller-identity"
echo ""

echo -e "${GREEN}🚀 QUICK START GUIDE${NC}"
echo "==================="
echo ""

echo -e "${BLUE}Step 1: Validate Configuration${NC}"
echo "  ./validate-backend.sh    # Check GitHub Actions alignment"
echo "  ./test-init.sh          # Test init.sh functionality"
echo ""

echo -e "${BLUE}Step 2: Initialize Environments${NC}"
echo "  ./init.sh dev           # Initialize development environment"
echo "  ./init.sh prod          # Initialize production environment"
echo ""

echo -e "${BLUE}Step 3: Deploy (Choose One)${NC}"
echo "  Local Deployment:"
echo "    ./deploy.sh dev       # Deploy to development locally"
echo "    ./deploy.sh prod      # Deploy to production locally"
echo ""
echo "  GitHub Actions Deployment (Recommended):"
echo "    git push origin main  # Auto-deploys to dev"
echo "    # Use GitHub Actions UI for prod deployment"
echo ""

echo -e "${BLUE}Step 4: Test & Verify${NC}"
echo "  ./test-health-notification.sh dev   # Test dev notifications"
echo "  ./test-lambda-formatter.sh          # Test Lambda formatting"
echo ""

echo -e "${BLUE}Step 5: Cleanup (Optional)${NC}"
echo "  ./cleanup-project.sh    # Remove unnecessary files"
echo ""

echo -e "${CYAN}📚 AVAILABLE TOOLS & SCRIPTS${NC}"
echo "============================="
echo ""
echo -e "${GREEN}🔧 Core Scripts:${NC}"
echo "  • init.sh              - Initialize Terraform (GitHub Actions aligned)"
echo "  • deploy.sh            - Deploy to environments" 
echo "  • cleanup-project.sh   - Clean unnecessary files"
echo ""
echo -e "${GREEN}🧪 Testing & Validation:${NC}"
echo "  • validate-backend.sh  - Validate GitHub Actions alignment"
echo "  • test-init.sh         - Test initialization functionality"
echo "  • test-health-notification.sh - Test health notifications"
echo "  • test-lambda-formatter.sh - Test Lambda function"
echo ""
echo -e "${GREEN}📋 Documentation:${NC}"
echo "  • README.md           - Complete project documentation"
echo "  • TAGGING_STRATEGY.md - Resource tagging guidelines"  
echo "  • deployment.md       - Deployment procedures"
echo ""

echo -e "${YELLOW}🔍 CONFIGURATION VALIDATION${NC}"
echo "============================"
echo ""

# Check if AWS credentials work
echo -e "${BLUE}Checking AWS credentials...${NC}"
if aws sts get-caller-identity >/dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✅ AWS credentials configured (Account: $ACCOUNT_ID)${NC}"
else
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo -e "   Run: aws configure"
fi

# Check S3 bucket access
echo -e "${BLUE}Checking S3 bucket access...${NC}"
if aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ S3 bucket accessible${NC}"
else
    echo -e "${RED}❌ Cannot access S3 bucket: $BUCKET_NAME${NC}"
    echo -e "   Create bucket: aws s3 mb s3://$BUCKET_NAME"
    echo -e "   Enable versioning: aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled"
fi

# Check backend configurations using improved parsing
echo -e "${BLUE}Checking backend configurations...${NC}"
DEV_OK=false
PROD_OK=false

if [ -f "backend/dev.hcl" ]; then
    DEV_KEY=$(extract_value "backend/dev.hcl" "key")
    if [ "$DEV_KEY" = "health-notifications/dev/terraform.tfstate" ]; then
        echo -e "${GREEN}✅ Dev backend configuration correct${NC}"
        DEV_OK=true
    else
        echo -e "${RED}❌ Dev backend key mismatch: '$DEV_KEY'${NC}"
    fi
else
    echo -e "${RED}❌ Dev backend configuration missing${NC}"
fi

if [ -f "backend/prod.hcl" ]; then
    PROD_KEY=$(extract_value "backend/prod.hcl" "key")
    if [ "$PROD_KEY" = "health-notifications/prod/terraform.tfstate" ]; then
        echo -e "${GREEN}✅ Prod backend configuration correct${NC}"
        PROD_OK=true
    else
        echo -e "${RED}❌ Prod backend key mismatch: '$PROD_KEY'${NC}"
    fi
else
    echo -e "${RED}❌ Prod backend configuration missing${NC}"
fi

echo ""

if [ "$DEV_OK" = true ] && [ "$PROD_OK" = true ]; then
    echo -e "${GREEN}🎉 READY TO GO!${NC}"
    echo "==============="
    echo ""
    echo -e "${GREEN}Your Terraform project is perfectly aligned with GitHub Actions!${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Run: ./init.sh dev"
    echo "  2. Run: ./deploy.sh dev"
    echo "  3. Test: ./test-health-notification.sh dev"
    echo "  4. Push to GitHub for automated deployments"
    echo ""
    echo -e "${CYAN}🚀 Happy Terraforming!${NC}"
else
    echo -e "${YELLOW}⚠️  CONFIGURATION NEEDS ATTENTION${NC}"
    echo "==================================="
    echo ""
    echo -e "${YELLOW}Run these commands to fix:${NC}"
    echo "  1. ./validate-backend.sh  # See detailed issues"
    echo "  2. ./init.sh dev         # Fix dev configuration"  
    echo "  3. ./init.sh prod        # Fix prod configuration"
    echo "  4. Run this script again to verify"
fi

echo ""
echo -e "${CYAN}📞 Need Help?${NC}"
echo "============="
echo "  • Check README.md for detailed documentation"
echo "  • Run ./validate-backend.sh for detailed validation"
echo "  • Ensure your GitHub TF_STATE_BUCKET secret matches: $BUCKET_NAME"
echo "  • Verify AWS credentials and S3 bucket access"
echo ""

echo -e "${BLUE}Made with ❤️  - Your Terraform project is now production-ready!${NC}"
