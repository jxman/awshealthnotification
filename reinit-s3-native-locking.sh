#!/bin/bash
# Reinitialize Terraform with S3 Native Locking (use_lockfile = true)

set -e

echo "🚀 Reinitializing Terraform with S3 Native Locking"
echo "=================================================="
echo ""

echo "📋 Configuration Summary:"
echo "• Backend: S3 with use_lockfile = true"
echo "• Bucket: jxman-terraform-state-bucket"
echo "• No DynamoDB required"
echo "• Terraform v$(terraform version -json | jq -r '.terraform_version')"
echo ""

# Function to reinitialize an environment
reinit_environment() {
    local env=$1
    echo "🔧 Reinitializing $env environment..."
    echo ""
    
    cd "environments/$env"
    
    # Backup existing state if it exists
    if [ -f .terraform/terraform.tfstate ]; then
        cp .terraform/terraform.tfstate .terraform/terraform.tfstate.backup.$(date +%s)
        echo "✅ Backed up existing Terraform state"
    fi
    
    # Reinitialize with new backend config
    echo "Initializing with S3 native locking backend..."
    if terraform init -reconfigure -backend-config="../../backend/$env.hcl"; then
        echo "✅ $env environment initialized successfully!"
    else
        echo "❌ Failed to initialize $env environment"
        return 1
    fi
    
    # Test basic operation
    echo "Testing terraform plan..."
    if terraform plan -input=false > /dev/null 2>&1; then
        echo "✅ $env environment working correctly!"
    else
        echo "⚠️  $env environment plan had issues (check manually)"
    fi
    
    echo ""
    cd - > /dev/null
}

# Reinitialize dev environment
echo "🔧 Step 1: Dev Environment"
echo "=========================="
reinit_environment "dev"

# Reinitialize prod environment
echo "🔧 Step 2: Prod Environment" 
echo "=========================="
reinit_environment "prod"

echo "🏁 Reinitialization Complete!"
echo ""

echo "📊 Summary:"
echo "==========="
echo "✅ Dev environment: S3 native locking active"
echo "✅ Prod environment: S3 native locking active"
echo "✅ Backend config: use_lockfile = true"
echo "✅ No DynamoDB dependency"
echo ""

echo "🧪 Next Steps:"
echo "1. Test both environments: terraform plan"
echo "2. Commit changes: git add . && git commit -m 'feat: implement S3 native locking'"
echo "3. Test GitHub Actions: git push origin main"
echo "4. Verify workflow runs successfully"
echo ""

echo "💡 GitHub Secrets Required:"
echo "• TF_STATE_BUCKET (already configured)"
echo "• No TF_STATE_LOCK_TABLE needed (removed)"
echo ""

echo "🎉 S3 Native Locking Implementation Complete!"
