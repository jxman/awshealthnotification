#!/bin/bash

# AWS Health Notification Terraform Initialization Script
# This script initializes Terraform to match the GitHub Actions workflow configuration
# Usage: ./init.sh <environment>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 AWS Health Notification - Terraform Init${NC}"
echo "=============================================="
echo -e "${BLUE}🔗 Matching GitHub Actions workflow configuration${NC}"

# Check if environment argument is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Environment not specified${NC}"
    echo ""
    echo "Usage: ./init.sh <environment>"
    echo "Available environments: dev, prod"
    echo ""
    echo "Examples:"
    echo "  ./init.sh dev   # Initialize development environment"
    echo "  ./init.sh prod  # Initialize production environment"
    exit 1
fi

ENV=$1

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo -e "${RED}❌ Error: Invalid environment '$ENV'${NC}"
    echo "Available environments: dev, prod"
    exit 1
fi

echo -e "Environment: ${YELLOW}$ENV${NC}"
echo ""

# Check if environment directory exists
ENV_DIR="environments/$ENV"
if [ ! -d "$ENV_DIR" ]; then
    echo -e "${RED}❌ Error: Environment directory '$ENV_DIR' not found${NC}"
    exit 1
fi

# Check if terraform.tfvars exists
TFVARS_FILE="$ENV_DIR/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}❌ Error: terraform.tfvars not found at $TFVARS_FILE${NC}"
    echo ""
    echo "Please create $TFVARS_FILE or copy from terraform.tfvars.example"
    exit 1
fi

# Check if backend configuration exists
BACKEND_CONFIG="backend/$ENV.hcl"
if [ ! -f "$BACKEND_CONFIG" ]; then
    echo -e "${RED}❌ Error: Backend configuration not found at $BACKEND_CONFIG${NC}"
    echo ""
    echo "Creating GitHub Actions compatible backend configuration..."

    # Create backend directory if it doesn't exist
    mkdir -p backend

    # Prompt for S3 bucket name (should match GitHub secret TF_STATE_BUCKET)
    echo -e "${YELLOW}⚙️  Backend Configuration Setup${NC}"
    echo "This should match your GitHub Actions TF_STATE_BUCKET secret"
    echo ""

    read -p "S3 Bucket name for Terraform state (from GitHub secret): " S3_BUCKET
    if [ -z "$S3_BUCKET" ]; then
        echo -e "${RED}❌ Error: S3 bucket name is required${NC}"
        exit 1
    fi

    # Create backend configuration matching GitHub Actions pattern
    cat > "$BACKEND_CONFIG" << EOF
# S3 backend configuration for $ENV environment
# This matches the GitHub Actions workflow configuration pattern
bucket       = "$S3_BUCKET"
key          = "health-notifications/$ENV/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
EOF

    echo ""
    echo -e "${GREEN}✅ Backend configuration created matching GitHub Actions pattern${NC}"
    echo ""
    echo -e "${BLUE}📄 Created backend configuration:${NC}"
    cat "$BACKEND_CONFIG"
    echo ""
fi

# Validate backend configuration
echo -e "${BLUE}🔍 Validating backend configuration...${NC}"

# Check required parameters
if ! grep -q "bucket.*=" "$BACKEND_CONFIG"; then
    echo -e "${RED}❌ Error: Backend configuration missing 'bucket' parameter${NC}"
    exit 1
fi

if ! grep -q "key.*=" "$BACKEND_CONFIG"; then
    echo -e "${RED}❌ Error: Backend configuration missing 'key' parameter${NC}"
    exit 1
fi

# Validate key pattern matches GitHub Actions
EXPECTED_KEY="health-notifications/$ENV/terraform.tfstate"
ACTUAL_KEY=$(grep "key.*=" "$BACKEND_CONFIG" | sed 's/.*=\s*"\([^"]*\)".*/\1/' | tr -d ' ')

if [ "$ACTUAL_KEY" != "$EXPECTED_KEY" ]; then
    echo -e "${YELLOW}⚠️  Warning: Key pattern doesn't match GitHub Actions workflow${NC}"
    echo "  Expected: $EXPECTED_KEY"
    echo "  Actual: $ACTUAL_KEY"
    echo ""
    read -p "Do you want to fix this automatically? [Y/n]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Fix the key pattern
        sed -i.bak "s|key.*=.*|key          = \"$EXPECTED_KEY\"|" "$BACKEND_CONFIG"
        echo -e "${GREEN}✅ Fixed key pattern to match GitHub Actions${NC}"
    fi
fi

# Check for S3 native locking
if ! grep -q "use_lockfile.*=.*true" "$BACKEND_CONFIG"; then
    echo -e "${YELLOW}⚠️  Adding S3 native locking to match GitHub Actions${NC}"
    if ! grep -q "use_lockfile" "$BACKEND_CONFIG"; then
        echo "use_lockfile = true" >> "$BACKEND_CONFIG"
    else
        sed -i.bak "s|use_lockfile.*=.*|use_lockfile = true|" "$BACKEND_CONFIG"
    fi
fi

echo -e "${GREEN}✅ Backend configuration validated${NC}"

# Show current backend configuration
echo ""
echo -e "${BLUE}📋 Backend Configuration (matches GitHub Actions):${NC}"
echo "─────────────────────────────────────────────────────"
cat "$BACKEND_CONFIG"
echo "─────────────────────────────────────────────────────"
echo ""

# Verify bucket access
BUCKET_NAME=$(grep "bucket.*=" "$BACKEND_CONFIG" | sed 's/.*=\s*"\([^"]*\)".*/\1/' | tr -d ' ')
echo -e "${BLUE}🔐 Verifying S3 bucket access...${NC}"
if aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ S3 bucket '$BUCKET_NAME' is accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Cannot access S3 bucket '$BUCKET_NAME'${NC}"
    echo "  Make sure:"
    echo "  1. AWS credentials are configured: aws configure"
    echo "  2. Bucket exists and you have access"
    echo "  3. Bucket name matches your GitHub TF_STATE_BUCKET secret"
    echo "  4. Try: aws s3 ls s3://$BUCKET_NAME"
    echo ""
fi

# Navigate to environment directory
echo -e "${BLUE}📁 Navigating to environment directory: $ENV_DIR${NC}"
cd "$ENV_DIR" || {
    echo -e "${RED}❌ Error: Failed to change to environment directory${NC}"
    exit 1
}

# Check if already initialized
if [ -d ".terraform" ]; then
    echo -e "${YELLOW}⚠️  Terraform already initialized in this environment${NC}"
    read -p "Do you want to reinitialize? This will reconfigure the backend. [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔄 Reinitializing Terraform...${NC}"
        rm -rf .terraform
        rm -f .terraform.lock.hcl
    else
        echo -e "${GREEN}✅ Using existing Terraform initialization${NC}"
        echo ""
        echo -e "${BLUE}📋 Next steps:${NC}"
        echo "  1. Review terraform.tfvars configuration"
        echo "  2. Run: terraform plan -var-file=terraform.tfvars"
        echo "  3. Or use: ../../deploy.sh $ENV"
        exit 0
    fi
fi

# Initialize Terraform
echo -e "${BLUE}🔧 Initializing Terraform for $ENV environment...${NC}"
echo "Using backend configuration: ../../$BACKEND_CONFIG"
echo ""

if terraform init -backend-config="../../$BACKEND_CONFIG"; then
    echo ""
    echo -e "${GREEN}✅ Terraform initialization successful!${NC}"
    echo ""
    echo -e "${BLUE}📋 Configuration Summary:${NC}"
    echo "  • Environment: $ENV"
    echo "  • State Key: health-notifications/$ENV/terraform.tfstate"
    echo "  • Backend: S3 with native locking"
    echo "  • Matches: GitHub Actions workflow ✓"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "  1. Review your terraform.tfvars configuration"
    echo "  2. Run: terraform plan -var-file=terraform.tfvars"
    echo "  3. Or use the deployment script: ../../deploy.sh $ENV"
    echo "  4. Deploy via GitHub Actions for production workflow"
    echo ""
    echo -e "${GREEN}🎉 Environment '$ENV' is ready and matches GitHub Actions!${NC}"
else
    echo ""
    echo -e "${RED}❌ Terraform initialization failed${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Troubleshooting tips:${NC}"
    echo "  1. Verify AWS credentials: aws configure list"
    echo "  2. Check S3 bucket access: aws s3 ls s3://$BUCKET_NAME"
    echo "  3. Ensure bucket name matches GitHub TF_STATE_BUCKET secret"
    echo "  4. Verify backend configuration is correct"
    exit 1
fi
