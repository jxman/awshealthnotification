#!/bin/bash
# Wrapper script for backward compatibility
# This script redirects to the organized location: scripts/utilities/setup-summary.sh

# Check if the target script exists
if [ ! -f "scripts/utilities/setup-summary.sh" ]; then
    echo "Error: Target script not found at scripts/utilities/setup-summary.sh"
    exit 1
fi

# Execute the target script with all arguments
exec "scripts/utilities/setup-summary.sh" "$@"
