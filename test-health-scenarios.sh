#!/bin/bash

# Test AWS Health Event Scenarios Script
# This script can test different types of health events

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-dev}"
SCENARIO="${2:-basic}"
REGION="${3:-us-east-1}"

echo -e "${GREEN}AWS Health Event Notification Test - Scenarios${NC}"
echo "============================================="
echo -e "Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "Scenario: ${YELLOW}${SCENARIO}${NC}"
echo -e "Region: ${YELLOW}${REGION}${NC}"
echo ""

# Function to send test event
send_test_event() {
    local service="$1"
    local status="$2"
    local event_type="$3"
    local category="$4"
    local description="$5"
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local event_id=$(date +%s)
    
    cat > test-event-${scenario}.json << EOF
[
  {
    "Source": "custom.health.test",
    "DetailType": "Custom Health Test Event",
    "Detail": "{\"eventArn\":\"arn:aws:health:${REGION}::event/${service}/TEST_EVENT/TEST_${event_id}\",\"service\":\"${service}\",\"eventTypeCode\":\"${event_type}\",\"eventTypeCategory\":\"${category}\",\"startTime\":\"${timestamp}\",\"endTime\":\"${timestamp}\",\"eventDescription\":[{\"language\":\"en_US\",\"latestDescription\":\"${description}\"}],\"statusCode\":\"${status}\",\"region\":\"${REGION}\",\"account\":\"$(aws sts get-caller-identity --query Account --output text)\"}"
  }
]
EOF

    echo -e "${BLUE}Sending ${scenario} test event...${NC}"
    aws events put-events --entries file://test-event-${scenario}.json --region "${REGION}"
    rm -f test-event-${scenario}.json
    echo -e "${GREEN}✓ Event sent${NC}\n"
    sleep 2
}

# Main test script (reuse the setup from previous script)
./test-health-notification.sh "${ENVIRONMENT}" "${REGION}" &
MAIN_PID=$!

# Wait for main script to set up
sleep 5

# Define scenarios
case "$SCENARIO" in
    "basic")
        echo -e "${YELLOW}Testing basic health event...${NC}"
        send_test_event "EC2" "open" "AWS_EC2_OPERATIONAL_ISSUE" "issue" \
            "TEST: Basic EC2 operational issue notification"
        ;;
    
    "multiservice")
        echo -e "${YELLOW}Testing multiple service events...${NC}"
        send_test_event "EC2" "open" "AWS_EC2_OPERATIONAL_ISSUE" "issue" \
            "TEST: EC2 experiencing high API error rates"
        
        send_test_event "RDS" "open" "AWS_RDS_MAINTENANCE_SCHEDULED" "scheduledChange" \
            "TEST: RDS maintenance window scheduled for this weekend"
        
        send_test_event "LAMBDA" "resolved" "AWS_LAMBDA_OPERATIONAL_ISSUE" "issue" \
            "TEST: Lambda issue has been resolved"
        ;;
    
    "severity")
        echo -e "${YELLOW}Testing different severity levels...${NC}"
        send_test_event "S3" "open" "AWS_S3_OPERATIONAL_ISSUE" "issue" \
            "CRITICAL: S3 bucket access issues in multiple regions"
        
        send_test_event "CLOUDWATCH" "open" "AWS_CLOUDWATCH_OPERATIONAL_NOTIFICATION" "notification" \
            "INFO: CloudWatch metrics delay of 5 minutes"
        ;;
    
    "resolved")
        echo -e "${YELLOW}Testing resolved event...${NC}"
        send_test_event "ECS" "closed" "AWS_ECS_OPERATIONAL_ISSUE" "issue" \
            "RESOLVED: ECS task scheduling delays have been resolved. Service is operating normally."
        ;;
    
    "account")
        echo -e "${YELLOW}Testing account-specific event...${NC}"
        send_test_event "BILLING" "open" "AWS_BILLING_NOTIFICATION" "accountNotification" \
            "TEST: Your AWS bill for this month exceeds your budget threshold"
        ;;
    
    "long")
        echo -e "${YELLOW}Testing long description...${NC}"
        send_test_event "EC2" "open" "AWS_EC2_INSTANCE_RETIREMENT" "scheduledChange" \
            "TEST: Long description event. $(printf 'This is a very long description that simulates a detailed AWS Health event. It includes multiple paragraphs of information about the issue, impact, and resolution steps. %.0s' {1..5})"
        ;;
    
    *)
        echo -e "${RED}Unknown scenario: ${SCENARIO}${NC}"
        echo "Available scenarios: basic, multiservice, severity, resolved, account, long"
        kill $MAIN_PID 2>/dev/null
        exit 1
        ;;
esac

# Wait for main script to complete
wait $MAIN_PID

echo -e "${GREEN}Scenario testing completed!${NC}"