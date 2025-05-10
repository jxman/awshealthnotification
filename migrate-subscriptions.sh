#!/bin/bash

# Migration script to remove subscription management from Terraform
# This script removes existing subscriptions from Terraform state

echo "AWS Health Notifications - Subscription Migration Script"
echo "======================================================"

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: ./migrate-subscriptions.sh <environment>"
    echo "Example: ./migrate-subscriptions.sh dev"
    exit 1
fi

ENV=$1
ENV_DIR="environments/$ENV"

# Check if environment exists
if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment '$ENV' not found"
    exit 1
fi

cd "$ENV_DIR" || exit

echo "Working in environment: $ENV"
echo "Initializing Terraform..."

# Initialize Terraform
terraform init -backend-config="../../backend/$ENV.hcl"

echo -e "\nCurrent subscriptions in Terraform state:"
terraform state list | grep subscription || echo "No subscriptions found in state"

# Store subscriptions before removal
echo -e "\nBacking up subscription details..."
terraform state list | grep subscription | while read -r resource; do
    echo "Resource: $resource"
    terraform state show "$resource" > "backup_${resource//\//_}.json"
done

echo -e "\nRemoving subscriptions from Terraform state..."
echo "This will NOT delete the actual subscriptions from AWS."

# Remove email subscriptions
terraform state list | grep "email_subscriptions" | while read -r resource; do
    echo "Removing: $resource"
    terraform state rm "$resource"
done

# Remove SMS subscriptions
terraform state list | grep "sms_subscriptions" | while read -r resource; do
    echo "Removing: $resource"
    terraform state rm "$resource"
done

echo -e "\nSubscriptions removed from Terraform state."
echo "The actual subscriptions still exist in AWS and will continue to work."
echo -e "\nNext steps:"
echo "1. Update your Terraform code to remove subscription resources"
echo "2. Run 'terraform plan' to verify no subscriptions will be destroyed"
echo "3. Apply the changes"
echo "4. Manage subscriptions manually through AWS Console"

echo -e "\nBackup files created in: $ENV_DIR"
ls backup_*.json 2>/dev/null || echo "No backup files created"