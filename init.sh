#!/bin/bash

# Overview: This script initializes Terraform for the specified environment.
# It reads the required variables from the terraform.tfvars file in the environment directory
# and creates a backend configuration file in the backend directory.
# Finally, it initializes Terraform with the specified backend configuration.
# Command line usage: ./init.sh <environment>  (e.g. ./init.sh prod)        

# Ensure the script stops on any error
set -e  

# Check if environment argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./init.sh <environment>"
    echo "Example: ./init.sh prod"
    exit 1
fi

ENV=$1

# Read variables from terraform.tfvars in the environment directory
TFVARS_FILE="environments/$ENV/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo "Error: terraform.tfvars not found for environment $TFVARS_FILE $ENV"
    exit 1
fi

# Extract variables
BUCKET=$(grep terraform_state_bucket "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
KEY=$(grep terraform_state_key "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
REGION=$(grep aws_region "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
DYNAMODB_TABLE=$(grep terraform_state_dynamodb_table "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')

# Create backend config directory if it doesn't exist
mkdir -p backend

# Create backend config
cat > "backend/$ENV.hcl" << EOF
bucket         = "${BUCKET}"
key            = "${KEY}"
region         = "${REGION}"
dynamodb_table = "${DYNAMODB_TABLE}"
encrypt        = true
EOF

# Navigate to environment directory and initialize Terraform
cd "environments/$ENV" || exit
terraform init -backend-config="../../backend/$ENV.hcl"