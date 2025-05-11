#!/bin/bash

# Test AWS Health Event Notification Script
# This script sends a test event through EventBridge to verify email formatting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"
CLEANUP_DELAY=30

echo -e "${GREEN}AWS Health Event Notification Test Script${NC}"
echo "========================================"
echo -e "Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "Region: ${YELLOW}${REGION}${NC}"
echo ""

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    
    # Restore original EventBridge rule
    echo "Restoring original EventBridge rule..."
    aws events put-rule \
        --name "${ENVIRONMENT}-health-event-notifications" \
        --event-pattern "${ORIGINAL_PATTERN}" \
        --region "${REGION}" >/dev/null 2>&1 || echo "Warning: Failed to restore rule"
    
    # Remove temporary files
    rm -f test-event-custom.json original-rule.json
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Set up cleanup trap
trap cleanup EXIT

# Step 1: Get the current EventBridge rule pattern
echo -e "${YELLOW}Step 1: Getting current EventBridge rule pattern...${NC}"
aws events describe-rule \
    --name "${ENVIRONMENT}-health-event-notifications" \
    --region "${REGION}" > original-rule.json || handle_error "Failed to get current rule"

ORIGINAL_PATTERN=$(jq -r '.EventPattern' original-rule.json)
echo "Original pattern saved"

# Step 2: Update EventBridge rule to accept test events
echo -e "\n${YELLOW}Step 2: Updating EventBridge rule to accept test events...${NC}"
TEST_PATTERN='{
    "source": ["aws.health", "custom.health.test"],
    "detail-type": ["AWS Health Event", "Custom Health Test Event"]
}'

aws events put-rule \
    --name "${ENVIRONMENT}-health-event-notifications" \
    --event-pattern "${TEST_PATTERN}" \
    --region "${REGION}" || handle_error "Failed to update rule"

echo "Rule updated to accept test events"

# Step 3: Create test event
echo -e "\n${YELLOW}Step 3: Creating test event...${NC}"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EVENT_ID=$(date +%s)

cat > test-event-custom.json << EOF
[
  {
    "Source": "custom.health.test",
    "DetailType": "Custom Health Test Event",
    "Detail": "{\"eventArn\":\"arn:aws:health:${REGION}::event/EC2/TEST_EVENT/TEST_${EVENT_ID}\",\"service\":\"EC2\",\"eventTypeCode\":\"AWS_EC2_TEST_NOTIFICATION\",\"eventTypeCategory\":\"issue\",\"startTime\":\"${TIMESTAMP}\",\"endTime\":\"${TIMESTAMP}\",\"eventDescription\":[{\"language\":\"en_US\",\"latestDescription\":\"TEST NOTIFICATION: This is a test AWS Health event to verify email formatting. Environment: ${ENVIRONMENT}. This simulates an EC2 operational issue with elevated API error rates. You should see proper formatting with section headers, dividers, and emojis. Test ID: ${EVENT_ID}\"}],\"statusCode\":\"open\",\"region\":\"${REGION}\",\"account\":\"$(aws sts get-caller-identity --query Account --output text)\"}"
  }
]
EOF

echo "Test event created with ID: ${EVENT_ID}"

# Step 4: Send test event
echo -e "\n${YELLOW}Step 4: Sending test event...${NC}"
RESULT=$(aws events put-events --entries file://test-event-custom.json --region "${REGION}")
FAILED_COUNT=$(echo "$RESULT" | jq -r '.FailedEntryCount')

if [ "$FAILED_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ Test event sent successfully!${NC}"
    EVENT_ID=$(echo "$RESULT" | jq -r '.Entries[0].EventId')
    echo "Event ID: ${EVENT_ID}"
else
    ERROR_MSG=$(echo "$RESULT" | jq -r '.Entries[0].ErrorMessage')
    handle_error "Failed to send test event: ${ERROR_MSG}"
fi

# Step 5: Wait for email delivery
echo -e "\n${YELLOW}Step 5: Waiting for email delivery...${NC}"
echo "Check your email for the test notification."
echo "The email should arrive within a few seconds."
echo ""
echo "Expected format includes:"
echo "  • Section headers with emojis"
echo "  • Visual dividers (━━━━━)"
echo "  • Structured information sections"
echo "  • Test ID: ${EVENT_ID}"

# Step 6: Wait before cleanup
echo -e "\n${YELLOW}Step 6: Waiting ${CLEANUP_DELAY} seconds before cleanup...${NC}"
echo "This gives time for the event to be processed."
echo "Press Ctrl+C to exit and cleanup immediately."

for ((i=${CLEANUP_DELAY}; i>0; i--)); do
    printf "\rCleanup in ${i} seconds... "
    sleep 1
done
echo ""

# Step 7: Check SNS topic for delivery status (optional)
echo -e "\n${YELLOW}Step 7: Checking SNS topic status...${NC}"
TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn, '${ENVIRONMENT}-health-event-notifications')].TopicArn" --output text --region "${REGION}")
if [ -n "$TOPIC_ARN" ]; then
    echo "SNS Topic: ${TOPIC_ARN}"
    
    # Get subscription count
    SUB_COUNT=$(aws sns list-subscriptions-by-topic --topic-arn "${TOPIC_ARN}" --query 'Subscriptions[].Protocol' --output text --region "${REGION}" | wc -w)
    echo "Active subscriptions: ${SUB_COUNT}"
fi

echo -e "\n${GREEN}Test completed successfully!${NC}"
echo "EventBridge rule will be restored to original state on exit."