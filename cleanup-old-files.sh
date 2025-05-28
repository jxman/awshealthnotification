#!/bin/bash
# Cleanup old DynamoDB-related files (optional)

echo "🧹 Cleaning up old DynamoDB-related files..."
echo ""

# Remove fallback configurations (no longer needed)
if [ -f "backend/dev-fallback.hcl" ]; then
    rm "backend/dev-fallback.hcl"
    echo "✅ Removed backend/dev-fallback.hcl"
fi

if [ -f "backend/prod-fallback.hcl" ]; then  
    rm "backend/prod-fallback.hcl"
    echo "✅ Removed backend/prod-fallback.hcl"
fi

if [ -f "backend/dev-with-lock.hcl" ]; then
    rm "backend/dev-with-lock.hcl" 
    echo "✅ Removed backend/dev-with-lock.hcl"
fi

if [ -f "backend/prod-with-lock.hcl" ]; then
    rm "backend/prod-with-lock.hcl"
    echo "✅ Removed backend/prod-with-lock.hcl"
fi

# Remove DynamoDB testing scripts (no longer needed)
if [ -f "test-dynamodb-locking.sh" ]; then
    rm "test-dynamodb-locking.sh"
    echo "✅ Removed test-dynamodb-locking.sh"
fi

# Remove experimental backend configs
if [ -f "backend/dev-experimental-1.hcl" ]; then
    rm "backend/dev-experimental-1.hcl"
    echo "✅ Removed backend/dev-experimental-1.hcl"
fi

if [ -f "backend/dev-experimental-2.hcl" ]; then
    rm "backend/dev-experimental-2.hcl"
    echo "✅ Removed backend/dev-experimental-2.hcl"
fi

echo ""
echo "🏁 Cleanup complete!"
echo ""
echo "📁 Current backend files:"
ls -la backend/
