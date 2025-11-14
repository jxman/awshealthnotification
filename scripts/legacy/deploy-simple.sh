#!/bin/bash

# Original simple deploy.sh - kept as backup
# This is the original version before enhancements

# Check if environment argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <environment>"
    echo "Example: ./deploy.sh prod"
    exit 1
fi

ENV=$1
ENV_DIR="environments/$ENV"

# Check if environment exists
if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment '$ENV' not found"
    exit 1
fi

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Navigate to environment directory
cd "$ENV_DIR" || handle_error "Failed to change to environment directory"

# Run init if .terraform directory doesn't exist
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init -backend-config="../../backend/$ENV.hcl" || handle_error "Terraform init failed"
fi

# Run terraform plan
echo "Planning deployment for $ENV environment..."
terraform plan -out=tfplan || handle_error "Terraform plan failed"

# Ask for confirmation
read -p "Do you want to apply these changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying changes..."
    terraform apply tfplan || handle_error "Terraform apply failed"
    rm tfplan
    echo "Deployment complete!"
else
    echo "Deployment cancelled"
    rm tfplan
fi
