#!/bin/bash
# Quick S3 locking test - check if concurrent operations are handled

echo "🧪 Quick S3 Locking Test"
echo "========================"
echo ""

cd environments/dev

echo "📋 Testing concurrent access behavior..."
echo ""

# Start a plan in the background that takes some time
echo "Starting background terraform plan..."
timeout 30s terraform plan -input=false > plan1.log 2>&1 &
PLAN1_PID=$!

# Wait a moment for it to start
sleep 2

# Try to start another plan immediately
echo "Starting concurrent terraform plan..."
if timeout 10s terraform plan -input=false -lock-timeout=5s > plan2.log 2>&1; then
    echo "✅ Second plan completed successfully"
    echo "⚠️  This suggests NO LOCKING is active"
else
    echo "❌ Second plan failed or timed out"
    echo "✅ This suggests LOCKING is working"
fi

# Wait for background plan to complete
wait $PLAN1_PID

echo ""
echo "📋 Results Analysis:"
echo ""

# Check for lock-related messages in logs
if grep -i "lock\|locking\|timeout" plan1.log plan2.log; then
    echo ""
    echo "✅ Found locking-related messages"
else
    echo "ℹ️  No locking messages found"
fi

echo ""
echo "📄 Plan 1 Log (first 10 lines):"
head -10 plan1.log

echo ""
echo "📄 Plan 2 Log (first 10 lines):"
head -10 plan2.log

# Cleanup
rm -f plan1.log plan2.log

echo ""
echo "🏁 Quick test complete!"
