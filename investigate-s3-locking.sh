#!/bin/bash
# Script to investigate S3 native locking capabilities

echo "🔍 Investigating Terraform S3 Native Locking Capabilities"
echo "=========================================================="
echo ""

# Check Terraform version
echo "📋 Terraform Version:"
terraform version
echo ""

# Check available backend configurations
echo "📋 S3 Backend Configuration Options:"
echo "Creating test backend config to see available options..."

# Create test directory
mkdir -p /tmp/terraform-s3-test
cd /tmp/terraform-s3-test

# Create minimal test configuration
cat > main.tf << 'EOF'
terraform {
  backend "s3" {
    # We'll test various configurations here
  }
}
EOF

echo ""
echo "📋 Testing S3 Backend Init Help:"
terraform init -help 2>&1 | grep -A 10 -B 5 "s3\|lock" || echo "No specific S3 lock info in help"

echo ""
echo "📋 Attempting to check backend schema:"

# Test different possible S3 native locking configurations
echo ""
echo "🧪 Testing Potential S3 Native Locking Options:"

# Test 1: use_lockfile option
echo ""
echo "Test 1: Checking 'use_lockfile' option..."
cat > backend-test1.hcl << 'EOF'
bucket       = "test-bucket"
key          = "test.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
EOF

terraform init -backend-config=backend-test1.hcl -input=false 2>&1 | head -20

# Test 2: lock_file option
echo ""
echo "Test 2: Checking 'lock_file' option..."
cat > backend-test2.hcl << 'EOF'
bucket    = "test-bucket"
key       = "test.tfstate"
region    = "us-east-1"
encrypt   = true
lock_file = true
EOF

terraform init -backend-config=backend-test2.hcl -input=false 2>&1 | head -20

# Test 3: native_locking option
echo ""
echo "Test 3: Checking 'native_locking' option..."
cat > backend-test3.hcl << 'EOF'
bucket         = "test-bucket"
key            = "test.tfstate"
region         = "us-east-1"
encrypt        = true
native_locking = true
EOF

terraform init -backend-config=backend-test3.hcl -input=false 2>&1 | head -20

# Test 4: Check official documentation
echo ""
echo "📚 Checking Terraform Documentation:"
echo "You should also check:"
echo "1. https://developer.hashicorp.com/terraform/language/settings/backends/s3"
echo "2. Recent Terraform release notes"
echo "3. Terraform GitHub issues/discussions about S3 native locking"

# Cleanup
cd - > /dev/null
rm -rf /tmp/terraform-s3-test

echo ""
echo "🏁 Investigation Complete!"
echo ""
echo "Next steps:"
echo "1. Review the output above for any supported S3 locking options"
echo "2. Check Terraform documentation for your version"
echo "3. Look for recent GitHub issues/PRs about S3 native locking"
