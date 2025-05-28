#!/bin/bash
# Test S3 Native Locking with use_lockfile=true

set -e

echo "🚀 Testing S3 Native Locking with 'use_lockfile=true'"
echo "===================================================="
echo ""

echo "📋 Terraform Version:"
terraform version
echo ""

cd environments/dev

echo "🔧 Step 1: Initialize with new backend configuration"
echo ""

# Backup current state if exists
if [ -f .terraform/terraform.tfstate ]; then
    cp .terraform/terraform.tfstate .terraform/terraform.tfstate.backup.$(date +%s)
    echo "✅ Backed up existing Terraform state"
fi

# Initialize with the new backend configuration
echo "Initializing Terraform with use_lockfile=true..."
if terraform init -reconfigure -backend-config=../../backend/dev.hcl; then
    echo "✅ Terraform init successful!"
else
    echo "❌ Terraform init failed"
    exit 1
fi

echo ""
echo "🔬 Step 2: Test locking behavior"
echo ""

# Function to test concurrent operations
test_concurrent_operations() {
    echo "Testing concurrent terraform operations..."
    
    # Start a plan that will hold the lock
    echo "Starting first terraform plan (should acquire lock)..."
    timeout 60s terraform plan -input=false -detailed-exitcode > plan1.log 2>&1 &
    PLAN1_PID=$!
    
    # Give it time to start and acquire lock
    sleep 3
    
    # Try to start another plan immediately (should be blocked by lock)
    echo "Starting second terraform plan (should wait for lock)..."
    START_TIME=$(date +%s)
    
    if timeout 15s terraform plan -input=false -lock-timeout=10s > plan2.log 2>&1; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo "✅ Second plan completed in ${DURATION}s"
        
        if [ $DURATION -gt 8 ]; then
            echo "🔒 Duration suggests locking mechanism is working!"
        else
            echo "⚠️  Duration suggests no locking (completed too quickly)"
        fi
    else
        echo "❌ Second plan failed or timed out"
        echo "🔒 This suggests locking is working (second plan was blocked)"
    fi
    
    # Wait for first plan to complete
    wait $PLAN1_PID
    PLAN1_EXIT=$?
    
    echo ""
    echo "📋 Plan 1 exit code: $PLAN1_EXIT"
    
    # Check for lock-related messages
    echo ""
    echo "🔍 Checking for lock-related messages in logs:"
    
    if grep -i "lock\|locking\|acquire\|release" plan1.log plan2.log; then
        echo "✅ Found locking-related messages!"
    else
        echo "ℹ️  No explicit locking messages found"
    fi
    
    echo ""
    echo "📄 First few lines of Plan 1 log:"
    head -5 plan1.log
    
    echo ""
    echo "📄 First few lines of Plan 2 log:"
    head -5 plan2.log
    
    # Cleanup
    rm -f plan1.log plan2.log
}

# Run the concurrent operations test
test_concurrent_operations

echo ""
echo "🔬 Step 3: Check state file and lock file"
echo ""

# Check if a lock file exists in S3
echo "Checking for lock files in S3..."
if aws s3 ls s3://jxman-terraform-state-bucket/health-notifications/dev/ | grep -i lock; then
    echo "✅ Found lock-related files in S3!"
    aws s3 ls s3://jxman-terraform-state-bucket/health-notifications/dev/ | grep -i lock
else
    echo "ℹ️  No obvious lock files found in S3"
fi

# Check for lock metadata
echo ""
echo "Checking state file metadata..."
aws s3api head-object --bucket jxman-terraform-state-bucket --key health-notifications/dev/terraform.tfstate 2>/dev/null | jq '.Metadata // {}'

echo ""
echo "🔬 Step 4: Test explicit lock operations"
echo ""

# Test explicit lock/unlock commands
echo "Testing terraform force-unlock (if lock exists)..."
if terraform force-unlock -force 2>&1 | head -5; then
    echo "ℹ️  Force unlock command executed (check output above)"
else
    echo "ℹ️  No active locks to unlock"
fi

echo ""
echo "🏁 S3 Native Locking Test Complete!"
echo ""

echo "📊 Summary:"
echo "==========="
echo "• Terraform Version: $(terraform version -json | jq -r '.terraform_version')"
echo "• Backend Config: use_lockfile = true"
echo "• Init Status: ✅ Successful"
echo "• Review the concurrent operation results above to determine if locking is working"
echo ""

echo "💡 Interpretation Guide:"
echo "• If second plan was blocked/delayed → Locking is working! 🎉"
echo "• If both plans ran immediately → No locking active ⚠️"
echo "• Look for lock-related messages in the logs"
echo ""

echo "📚 Next steps:"
echo "1. Review the test results above"
echo "2. If locking works: Update prod environment and document"
echo "3. If locking doesn't work: Fall back to S3+DynamoDB approach"
echo "4. Test with prod environment if dev test is successful"
