#!/bin/bash

# Quick Final Cleanup - Remove All Temporary Scripts
# Run this to remove all the temporary files created during setup

echo "🧹 Quick Final Cleanup"
echo "====================="

# Files to remove (created during our troubleshooting session)
TEMP_FILES=(
    "quick-test.sh"
    "test-parsing.sh"
    "make-executable.sh"
    "final-cleanup.sh"
)

echo "Removing temporary files..."
REMOVED=0

for file in "${TEMP_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm "$file"
        echo "✓ Removed: $file"
        ((REMOVED++))
    fi
done

# Also remove any .bak files if they exist
for bakfile in *.bak; do
    if [ -f "$bakfile" ]; then
        rm "$bakfile"
        echo "✓ Removed backup: $bakfile"
        ((REMOVED++))
    fi
done

echo ""
if [ $REMOVED -gt 0 ]; then
    echo "✨ Removed $REMOVED temporary files"
else
    echo "✨ No temporary files found to remove"
fi

echo ""
echo "📋 Essential scripts preserved:"
echo "  • init.sh - Initialize environments"
echo "  • deploy.sh - Deploy to environments"
echo "  • validate-backend.sh - Validate configuration"
echo "  • setup-summary.sh - Project status"
echo "  • cleanup-project.sh - Main cleanup utility"
echo "  • test-health-notification.sh - Test notifications"
echo "  • test-lambda-formatter.sh - Test Lambda"
echo ""
echo "🎉 Project is now clean and ready for production!"
