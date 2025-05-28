#!/bin/bash
# Comprehensive S3 Native Locking Test Plan

set -e

echo "🧪 Comprehensive S3 Native Locking Test Plan"
echo "=============================================="
echo ""

# Function to test backend configuration
test_backend_config() {
    local config_file=$1
    local test_name=$2
    
    echo "🔬 Testing: $test_name"
    echo "Config file: $config_file"
    echo ""
    
    # Backup current backend if it exists
    if [ -f .terraform/terraform.tfstate ]; then
        cp .terraform/terraform.tfstate .terraform/terraform.tfstate.backup
    fi
    
    # Try to initialize with the test config
    echo "Attempting terraform init..."
    if terraform init -reconfigure -backend-config="$config_file" -input=false > init.log 2>&1; then
        echo "✅ Init successful!"
        
        # Check if locking is working
        echo "Testing locking mechanism..."
        if terraform plan -lock-timeout=5s > plan.log 2>&1; then
            echo "✅ Plan successful!"
            
            # Check for locking messages in logs
            if grep -i "lock\|locking" init.log plan.log > /dev/null 2>&1; then
                echo "📋 Locking messages found:"
                grep -i "lock\|locking" init.log plan.log | head -5
            else
                echo "ℹ️  No explicit locking messages found"
            fi
        else
            echo "⚠️  Plan failed"
            cat plan.log | head -10
        fi
    else
        echo "❌ Init failed"
        cat init.log | head -10
    fi
    
    echo ""
    echo "---"
    echo ""
}

# Ensure we're in the right directory
cd environments/dev

echo "📋 Current Terraform Version:"
terraform version
echo ""

# Test 1: Current S3-only configuration
echo "🔬 Test 1: Current S3-only Configuration"
test_backend_config "../../backend/dev.hcl" "Current S3-only"

# Test 2: Traditional S3 + DynamoDB (for comparison)
if [ -f "../../backend/dev-with-lock.hcl" ]; then
    echo "🔬 Test 2: Traditional S3 + DynamoDB"
    test_backend_config "../../backend/dev-with-lock.hcl" "S3 + DynamoDB"
fi

# Research online sources
echo "🔍 Research Checklist:"
echo ""
echo "1. Check Terraform Changelog for S3 backend improvements:"
echo "   https://github.com/hashicorp/terraform/blob/main/CHANGELOG.md"
echo ""
echo "2. Search for S3 native locking issues/discussions:"
echo "   https://github.com/hashicorp/terraform/issues?q=s3+lock"
echo ""
echo "3. Check AWS Provider changelog:"
echo "   https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md"
echo ""
echo "4. Look for recent blog posts/documentation updates about S3 locking"
echo ""

# Check S3 bucket configuration
echo "📋 S3 Bucket Configuration Check:"
echo "Checking if your S3 bucket has versioning enabled (required for safe state management):"

if aws s3api get-bucket-versioning --bucket jxman-terraform-state-bucket 2>/dev/null; then
    echo "✅ Successfully checked bucket versioning"
else
    echo "⚠️  Could not check bucket versioning (permissions or bucket doesn't exist)"
fi

echo ""

# Check for S3 Object Lock
echo "📋 S3 Object Lock Check:"
echo "Checking if your S3 bucket has Object Lock enabled:"

if aws s3api get-object-lock-configuration --bucket jxman-terraform-state-bucket 2>/dev/null; then
    echo "✅ Object Lock configuration found"
else
    echo "ℹ️  No Object Lock configuration (this is normal for most buckets)"
fi

echo ""
echo "🏁 Test plan complete!"
echo ""
echo "💡 Next Steps:"
echo "1. Review the test results above"
echo "2. Research the provided links"
echo "3. Consider filing a GitHub issue if S3 native locking isn't available"
echo "4. Decide on fallback approach (S3-only vs S3+DynamoDB)"

# Cleanup
rm -f init.log plan.log
