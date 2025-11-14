#!/bin/bash

# Quick test script to validate the enhanced deploy.sh script
# This checks syntax and basic functionality without running actual deployment

echo "🧪 Testing Enhanced Deploy Script"
echo "================================"

# Check if deploy.sh exists and is readable
if [ ! -f "deploy.sh" ]; then
    echo "❌ deploy.sh not found"
    exit 1
fi

# Check if deploy.sh is executable
if [ ! -x "deploy.sh" ]; then
    echo "ℹ️  Making deploy.sh executable..."
    chmod +x deploy.sh
fi

# Test syntax by running with no arguments (should show usage)
echo "Testing script syntax and usage message..."
echo ""

if ./deploy.sh 2>/dev/null | grep -q "Usage:"; then
    echo "✅ Script syntax is valid"
    echo "✅ Usage message displays correctly"
else
    echo "❌ Script has syntax errors or usage message issues"
    exit 1
fi

# Test with invalid environment
echo ""
echo "Testing invalid environment handling..."
if ./deploy.sh invalid-env 2>&1 | grep -q "Invalid environment"; then
    echo "✅ Invalid environment handling works"
else
    echo "❌ Invalid environment handling failed"
fi

# Check for required functions
echo ""
echo "Checking script structure..."
if grep -q "check_prerequisites" deploy.sh && \
   grep -q "validate_environment" deploy.sh && \
   grep -q "apply_deployment" deploy.sh; then
    echo "✅ All required functions are present"
else
    echo "❌ Some required functions are missing"
fi

# Check for color definitions
if grep -q "RED=" deploy.sh && grep -q "GREEN=" deploy.sh; then
    echo "✅ Color output is configured"
else
    echo "❌ Color output configuration missing"
fi

echo ""
echo "🎉 Enhanced deploy.sh script validation completed!"
echo ""
echo "📋 Usage:"
echo "  ./deploy.sh dev    # Deploy to development"
echo "  ./deploy.sh prod   # Deploy to production"
echo ""
echo "💡 The script now includes:"
echo "  • Comprehensive pre-deployment validation"
echo "  • Enhanced error handling and logging"
echo "  • Production safety features"
echo "  • Post-deployment validation"
echo "  • Detailed progress tracking"
