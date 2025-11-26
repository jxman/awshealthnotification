#!/bin/bash

# Test script for init.sh functionality and GitHub Actions alignment
# This script validates that init.sh works correctly and matches CI/CD config

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🧪 Testing init.sh Script & GitHub Actions Alignment${NC}"
echo "=================================================="
echo ""

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

# Test 1: No arguments
echo -e "${BLUE}Test 1: No arguments provided${NC}"
if ./init.sh 2>/dev/null; then
    echo -e "${RED}❌ FAIL: Should have failed with no arguments${NC}"
else
    echo -e "${GREEN}✅ PASS: Correctly failed with no arguments${NC}"
fi
echo ""

# Test 2: Invalid environment
echo -e "${BLUE}Test 2: Invalid environment${NC}"
if ./init.sh invalid 2>/dev/null; then
    echo -e "${RED}❌ FAIL: Should have failed with invalid environment${NC}"
else
    echo -e "${GREEN}✅ PASS: Correctly rejected invalid environment${NC}"
fi
echo ""

# Test 3: GitHub Actions pattern validation
echo -e "${BLUE}Test 3: GitHub Actions workflow alignment${NC}"
GITHUB_WORKFLOW=".github/workflows/terraform.yml"

if [ -f "$GITHUB_WORKFLOW" ]; then
    echo -e "${GREEN}✅ GitHub Actions workflow found${NC}"

    # Check for expected patterns
    if grep -q "health-notifications/.*terraform.tfstate" "$GITHUB_WORKFLOW"; then
        echo -e "${GREEN}✅ Workflow uses expected state key pattern${NC}"
    else
        echo -e "${YELLOW}⚠️  Workflow state key pattern may differ${NC}"
    fi

    if grep -q "use_lockfile = true" "$GITHUB_WORKFLOW"; then
        echo -e "${GREEN}✅ Workflow uses S3 native locking${NC}"
    else
        echo -e "${YELLOW}⚠️  Workflow locking method may differ${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  GitHub Actions workflow not found${NC}"
fi
echo ""

# Test 4: Backend configuration validation
echo -e "${BLUE}Test 4: Backend configuration alignment${NC}"
PASS_COUNT=0
TOTAL_TESTS=8

# Expected patterns from GitHub Actions
EXPECTED_DEV_KEY="health-notifications/dev/terraform.tfstate"
EXPECTED_PROD_KEY="health-notifications/prod/terraform.tfstate"
EXPECTED_REGION="us-east-1"

# Check dev backend
if [ -f "backend/dev.hcl" ]; then
    echo -e "${GREEN}✅ backend/dev.hcl exists${NC}"
    ((PASS_COUNT++))

    DEV_KEY=$(extract_value "backend/dev.hcl" "key")
    if [ "$DEV_KEY" = "$EXPECTED_DEV_KEY" ]; then
        echo -e "${GREEN}✅ Dev key matches GitHub Actions pattern${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ Dev key mismatch: '$DEV_KEY' != '$EXPECTED_DEV_KEY'${NC}"
    fi

    DEV_REGION=$(extract_value "backend/dev.hcl" "region")
    if [ "$DEV_REGION" = "$EXPECTED_REGION" ]; then
        echo -e "${GREEN}✅ Dev region matches GitHub Actions${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ Dev region mismatch: '$DEV_REGION' != '$EXPECTED_REGION'${NC}"
    fi

    DEV_LOCKFILE=$(extract_value "backend/dev.hcl" "use_lockfile")
    if [ "$DEV_LOCKFILE" = "true" ]; then
        echo -e "${GREEN}✅ Dev uses S3 native locking${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ Dev not using S3 native locking: '$DEV_LOCKFILE'${NC}"
    fi
else
    echo -e "${RED}❌ backend/dev.hcl missing${NC}"
fi

# Check prod backend
if [ -f "backend/prod.hcl" ]; then
    echo -e "${GREEN}✅ backend/prod.hcl exists${NC}"
    ((PASS_COUNT++))

    PROD_KEY=$(extract_value "backend/prod.hcl" "key")
    if [ "$PROD_KEY" = "$EXPECTED_PROD_KEY" ]; then
        echo -e "${GREEN}✅ Prod key matches GitHub Actions pattern${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ Prod key mismatch: '$PROD_KEY' != '$EXPECTED_PROD_KEY'${NC}"
    fi

    PROD_REGION=$(extract_value "backend/prod.hcl" "region")
    if [ "$PROD_REGION" = "$EXPECTED_REGION" ]; then
        echo -e "${GREEN}✅ Prod region matches GitHub Actions${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ Prod region mismatch: '$PROD_REGION' != '$EXPECTED_REGION'${NC}"
    fi

    PROD_LOCKFILE=$(extract_value "backend/prod.hcl" "use_lockfile")
    if [ "$PROD_LOCKFILE" = "true" ]; then
        echo -e "${GREEN}✅ Prod uses S3 native locking${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ Prod not using S3 native locking: '$PROD_LOCKFILE'${NC}"
    fi
else
    echo -e "${RED}❌ backend/prod.hcl missing${NC}"
fi

echo ""
echo -e "${BLUE}Backend Alignment Results: ${PASS_COUNT}/${TOTAL_TESTS} passed${NC}"

# Test 5: Display configurations
echo ""
echo -e "${BLUE}Test 5: Configuration Summary${NC}"
echo -e "${YELLOW}Dev backend configuration:${NC}"
echo "──────────────────────────"
if [ -f "backend/dev.hcl" ]; then
    cat backend/dev.hcl
else
    echo "File not found"
fi
echo "──────────────────────────"
echo ""

echo -e "${YELLOW}Prod backend configuration:${NC}"
echo "──────────────────────────"
if [ -f "backend/prod.hcl" ]; then
    cat backend/prod.hcl
else
    echo "File not found"
fi
echo "──────────────────────────"
echo ""

# Test 6: S3 bucket validation
echo -e "${BLUE}Test 6: S3 bucket configuration${NC}"
DEV_BUCKET=$(extract_value "backend/dev.hcl" "bucket")
PROD_BUCKET=$(extract_value "backend/prod.hcl" "bucket")

echo "Dev bucket: '$DEV_BUCKET'"
echo "Prod bucket: '$PROD_BUCKET'"

if [ "$DEV_BUCKET" = "$PROD_BUCKET" ] && [ -n "$DEV_BUCKET" ]; then
    echo -e "${GREEN}✅ Dev and Prod use same S3 bucket: $DEV_BUCKET${NC}"
    echo -e "${GREEN}✅ Matches GitHub Actions single bucket approach${NC}"

    # Test bucket access if possible
    if aws s3 ls "s3://$DEV_BUCKET" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ S3 bucket is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  S3 bucket access test failed (check AWS credentials)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Dev bucket: '$DEV_BUCKET'${NC}"
    echo -e "${YELLOW}⚠️  Prod bucket: '$PROD_BUCKET'${NC}"
    if [ "$DEV_BUCKET" != "$PROD_BUCKET" ]; then
        echo -e "${RED}❌ Buckets should match for GitHub Actions compatibility${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📋 GitHub Actions Compatibility Summary${NC}"
echo "========================================"

if [ $PASS_COUNT -eq $TOTAL_TESTS ] && [ "$DEV_BUCKET" = "$PROD_BUCKET" ]; then
    echo -e "${GREEN}🎉 Perfect alignment with GitHub Actions workflow!${NC}"
    echo ""
    echo -e "${GREEN}✅ Configuration matches CI/CD pipeline${NC}"
    echo -e "${GREEN}✅ State management is consistent${NC}"
    echo -e "${GREEN}✅ Both environments use same S3 bucket${NC}"
    echo -e "${GREEN}✅ Both environments use S3 native locking${NC}"
    echo -e "${GREEN}✅ Key patterns follow GitHub Actions format${NC}"
else
    echo -e "${YELLOW}⚠️  Some alignment issues found (${PASS_COUNT}/${TOTAL_TESTS} passed)${NC}"
    echo ""
    echo -e "${YELLOW}To achieve perfect alignment:${NC}"
    echo "  1. Run ./validate-backend.sh for detailed analysis"
    echo "  2. Use ./init.sh dev and ./init.sh prod to fix issues"
    echo "  3. Ensure S3 bucket matches GitHub TF_STATE_BUCKET secret"
fi

echo ""
echo -e "${BLUE}📝 Before using init.sh:${NC}"
echo "  1. Ensure AWS credentials are configured"
echo "  2. Verify S3 bucket exists and matches GitHub secret"
echo "  3. Update bucket names in backend/*.hcl if needed"
echo ""

echo -e "${YELLOW}📝 To test initialization:${NC}"
echo "  1. Run: ./validate-backend.sh (detailed validation)"
echo "  2. Run: ./init.sh dev (initialize dev)"
echo "  3. Run: ./init.sh prod (initialize prod)"
echo ""

echo -e "${GREEN}🚀 init.sh script testing complete!${NC}"
