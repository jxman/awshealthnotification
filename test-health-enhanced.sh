#!/bin/bash
# Enhanced test script with detailed debugging

set -euo pipefail

ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"
EVENT_ID=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Enhanced AWS Health Event Test${NC}"
echo -e "Environment: ${ENVIRONMENT}"
echo -e "Region: ${REGION}"
echo -e "Test ID: ${EVENT_ID}"
echo ""

# Step 1: Find Lambda function
echo -e "${YELLOW}📍 Step 1: Finding Lambda function...${NC}"
LAMBDA_NAME=$(aws lambda list-functions \
  --query "Functions[?contains(FunctionName, '${ENVIRONMENT}-health-event-formatter')].FunctionName" \
  --output text \
  --region "${REGION}")

if [ -z "$LAMBDA_NAME" ]; then
  echo -e "${RED}❌ Lambda function not found for environment: ${ENVIRONMENT}${NC}"
  echo -e "${YELLOW}Available functions:${NC}"
  aws lambda list-functions \
    --query "Functions[*].FunctionName" \
    --output table \
    --region "${REGION}"
  exit 1
fi

echo -e "${GREEN}✅ Found: ${LAMBDA_NAME}${NC}"

# Step 2: Check Lambda configuration
echo -e "${YELLOW}📋 Step 2: Checking Lambda configuration...${NC}"
LAMBDA_INFO=$(aws lambda get-function-configuration \
  --function-name "$LAMBDA_NAME" \
  --region "${REGION}")

RUNTIME=$(echo "$LAMBDA_INFO" | jq -r '.Runtime')
STATE=$(echo "$LAMBDA_INFO" | jq -r '.State')
LAST_MODIFIED=$(echo "$LAMBDA_INFO" | jq -r '.LastModified')

echo -e "Runtime: ${RUNTIME}"
echo -e "State: ${STATE}"
echo -e "Last Modified: ${LAST_MODIFIED}"

if [ "$RUNTIME" != "nodejs20.x" ]; then
  echo -e "${RED}⚠️  Warning: Runtime is ${RUNTIME}, expected nodejs20.x${NC}"
fi

if [ "$STATE" != "Active" ]; then
  echo -e "${RED}❌ Lambda function state is: ${STATE}${NC}"
  echo -e "${YELLOW}State reason: $(echo "$LAMBDA_INFO" | jq -r '.StateReason // "N/A"')${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Lambda function is active${NC}"

# Step 3: Check environment variables
echo -e "${YELLOW}📋 Step 3: Checking environment variables...${NC}"
ENV_VARS=$(echo "$LAMBDA_INFO" | jq -r '.Environment.Variables')
echo "$ENV_VARS" | jq '.'

SNS_TOPIC_ARN=$(echo "$ENV_VARS" | jq -r '.SNS_TOPIC_ARN // "NOT_SET"')
if [ "$SNS_TOPIC_ARN" = "NOT_SET" ] || [ "$SNS_TOPIC_ARN" = "null" ]; then
  echo -e "${RED}❌ SNS_TOPIC_ARN not set in Lambda environment${NC}"
  exit 1
fi

echo -e "${GREEN}✅ SNS Topic ARN: ${SNS_TOPIC_ARN}${NC}"

# Step 4: Verify SNS topic exists
echo -e "${YELLOW}📋 Step 4: Verifying SNS topic...${NC}"
if aws sns get-topic-attributes --topic-arn "$SNS_TOPIC_ARN" --region "${REGION}" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ SNS topic exists and accessible${NC}"
else
  echo -e "${RED}❌ SNS topic not accessible: ${SNS_TOPIC_ARN}${NC}"
  exit 1
fi

# Step 5: Create and send test event
echo -e "${YELLOW}🚀 Step 5: Creating test event...${NC}"
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
        "latestDescription": "TEST NOTIFICATION: Runtime verification test for ${RUNTIME}. Test ID: ${EVENT_ID}. Environment: ${ENVIRONMENT}."
      }
    ]
  }
}
EOF

echo -e "${GREEN}✅ Test event created${NC}"

# Step 6: Invoke Lambda function
echo -e "${YELLOW}🚀 Step 6: Invoking Lambda function...${NC}"
if aws lambda invoke \
  --function-name "$LAMBDA_NAME" \
  --payload file://test-event.json \
  --cli-binary-format raw-in-base64-out \
  --region "${REGION}" \
  response.json; then
  
  echo -e "${GREEN}✅ Lambda invocation successful${NC}"
  
  # Check response
  if [ -f response.json ]; then
    echo -e "${YELLOW}📋 Response:${NC}"
    cat response.json | jq '.' 2>/dev/null || cat response.json
    
    # Check for errors in response
    if jq -e '.errorMessage' response.json >/dev/null 2>&1; then
      echo -e "${RED}❌ Lambda function returned an error:${NC}"
      jq -r '.errorMessage' response.json
      echo -e "${YELLOW}Error details:${NC}"
      jq -r '.errorType // "Unknown"' response.json
      jq -r '.stackTrace[]? // empty' response.json
    fi
  fi
else
  echo -e "${RED}❌ Lambda invocation failed${NC}"
  exit 1
fi

# Step 7: Check CloudWatch logs
echo -e "${YELLOW}📊 Step 7: Checking CloudWatch logs...${NC}"
sleep 5  # Wait for logs to appear

LOG_GROUP="/aws/lambda/${LAMBDA_NAME}"
echo -e "Log group: ${LOG_GROUP}"

if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "${REGION}" --query 'logGroups[0]' >/dev/null 2>&1; then
  LATEST_LOG_STREAM=$(aws logs describe-log-streams \
    --log-group-name "${LOG_GROUP}" \
    --order-by LastEventTime \
    --descending \
    --limit 1 \
    --query 'logStreams[0].logStreamName' \
    --output text \
    --region "${REGION}" 2>/dev/null || echo "")

  if [ -n "$LATEST_LOG_STREAM" ] && [ "$LATEST_LOG_STREAM" != "None" ]; then
    echo -e "${GREEN}✅ Found log stream: ${LATEST_LOG_STREAM}${NC}"
    echo -e "${YELLOW}Recent log events:${NC}"
    aws logs get-log-events \
      --log-group-name "${LOG_GROUP}" \
      --log-stream-name "${LATEST_LOG_STREAM}" \
      --limit 20 \
      --query 'events[*].message' \
      --output text \
      --region "${REGION}" | tail -10
  else
    echo -e "${YELLOW}⚠️  No recent log streams found${NC}"
  fi
else
  echo -e "${RED}❌ Log group not found: ${LOG_GROUP}${NC}"
fi

# Cleanup
rm -f test-event.json response.json

echo ""
echo -e "${GREEN}🎉 Test completed!${NC}"
echo -e "${YELLOW}📧 Check your email/SMS for the test notification.${NC}"
echo -e "${BLUE}💡 If no notification received, check SNS subscriptions in AWS Console${NC}"
