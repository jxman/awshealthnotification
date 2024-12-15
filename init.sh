#!/bin/bash

# Read variables from terraform.tfvars
BUCKET=$(grep terraform_state_bucket terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
KEY=$(grep terraform_state_key terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
REGION=$(grep aws_region terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
DYNAMODB_TABLE=$(grep terraform_state_dynamodb_table terraform.tfvars | cut -d'=' -f2 | tr -d ' "')

# Create backend config
cat > backend.hcl << EOF
bucket         = "${BUCKET}"
key            = "${KEY}"
region         = "${REGION}"
dynamodb_table = "${DYNAMODB_TABLE}"
encrypt        = true
EOF

# Initialize Terraform
terraform init -backend-config=backend.hcl