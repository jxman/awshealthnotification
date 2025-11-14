#!/bin/bash

# Test script for the AWS Health Event Lambda Formatter
# This script creates a test event and invokes the Lambda function

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"
EVENT_ID=$(date +%s)

echo -e "${GREEN}AWS Health Event Lambda Formatter Test${NC}"
echo "========================================"
echo -e "Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "Region: ${YELLOW}${REGION}${NC}"
echo ""

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Step 1: Find the Lambda function
echo -e "${YELLOW}Step 1: Finding Lambda function...${NC}"
LAMBDA_NAME=$(aws lambda list-functions \
  --query "Functions[?contains(FunctionName, '${ENVIRONMENT}-health-event-formatter')].FunctionName" \
  --output text \
  --region "${REGION}") || handle_error "Failed to find Lambda function"

if [ -z "$LAMBDA_NAME" ]; then
    handle_error "Lambda function not found. Make sure it has been deployed."
fi

echo "Found Lambda function: ${LAMBDA_NAME}"

# Step 2: Create a test event
echo -e "\n${YELLOW}Step 2: Creating test event...${NC}"
cat > test-event.json << EOF
{
  "source": "aws.health",
  "detail-type": "AWS Health Event",
  "time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "region": "${REGION}",
  "account": "$(aws sts get-caller-identity --query Account --output text)",
  "detail": {
    "eventArn": "arn:aws:health:${REGION}::event/EC2/AWS_EC2_OPERATIONAL_ISSUE/TEST_${EVENT_ID}",
    "service": "EC2",
    "eventTypeCode": "AWS_EC2_OPERATIONAL_ISSUE",
    "eventTypeCategory": "issue",
    "startTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "endTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "statusCode": "open",
    "eventDescription": [
      {
        "language": "en_US",
        "latestDescription": "TEST NOTIFICATION: This is a test AWS Health event to verify Lambda formatting. We are simulating an EC2 operational issue with elevated API error rates. Test ID: ${EVENT_ID}"
      }
    ]
  }
}
