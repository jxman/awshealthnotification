#!/bin/bash
# Wrapper script for backward compatibility
# This script redirects to the organized location: scripts/utilities/manage-logs.sh

# Check if the target script exists
if [ ! -f "scripts/utilities/manage-logs.sh" ]; then
    echo "Error: Target script not found at scripts/utilities/manage-logs.sh"
    exit 1
fi

# Execute the target script with all arguments
exec "scripts/utilities/manage-logs.sh" "$@"
