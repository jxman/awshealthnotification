#!/bin/bash
# Test script to verify Terraform Lambda code deployment

set -euo pipefail

ENVIRONMENT="${1:-dev}"

echo "🧪 Testing Terraform Lambda Code Deployment"
echo "Environment: $ENVIRONMENT"
echo ""

cd "environments/$ENVIRONMENT"

# Step 1: Check current state
echo "📋 Step 1: Checking current Lambda configuration..."
terraform show -json | jq -r '.values.root_module.child_modules[] | select(.address == "module.eventbridge") | .resources[] | select(.address == "module.eventbridge.aws_lambda_function.health_formatter") | .values.source_code_hash'

# Step 2: Add a test comment to force code change
echo ""
echo "📝 Step 2: Adding test comment to Lambda code..."
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
COMMENT="// Test deployment: $TIMESTAMP"

# Add comment to the top of the file if it doesn't exist
if ! grep -q "Test deployment:" ../../modules/eventbridge/lambda/index.js; then
    # Create a temporary file with the new comment
    echo "$COMMENT" > temp_index.js
    cat ../../modules/eventbridge/lambda/index.js >> temp_index.js
    mv temp_index.js ../../modules/eventbridge/lambda/index.js
    echo "✅ Test comment added"
else
    # Update existing comment
    sed -i'' -e "s|// Test deployment:.*|$COMMENT|" ../../modules/eventbridge/lambda/index.js
    echo "✅ Test comment updated"
fi

# Step 3: Check if Terraform detects the change
echo ""
echo "🔍 Step 3: Checking if Terraform detects the change..."
if terraform plan -detailed-exitcode -no-color | grep -q "aws_lambda_function.health_formatter"; then
    echo "✅ Terraform detected Lambda function changes!"
    
    # Show what changed
    echo ""
    echo "📋 Changes detected:"
    terraform plan -no-color | grep -A 10 -B 5 "aws_lambda_function.health_formatter" || true
    
else
    echo "❌ Terraform did not detect Lambda function changes"
    echo ""
    echo "🔍 Debugging information:"
    echo "Current source code hash:"
    cd ../../
    ls -la modules/eventbridge/lambda_function*.zip 2>/dev/null || echo "No ZIP files found"
    cd "environments/$ENVIRONMENT"
fi

echo ""
echo "🎯 Test completed!"
echo ""
echo "If changes were detected, you can deploy with:"
echo "  terraform apply"
