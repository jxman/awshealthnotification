# Multi-Region AWS Health Notifications - Implementation Plan

## Executive Summary

This document outlines the comprehensive plan to implement a high-availability, multi-region architecture for AWS Health event notifications with automatic de-duplication and failover capabilities.

## Current Architecture Baseline

### Existing Setup
- **Region:** us-east-1 only
- **Components:**
  - EventBridge rule capturing AWS Health events
  - Lambda function (Node.js 20.x) formatting notifications
  - SNS topic distributing notifications
  - S3 backend with native locking for Terraform state
- **Deployment:** GitHub Actions with manual dispatch
- **Environments:** dev (disabled), prod (enabled)

### Current Limitations
- ❌ No regional redundancy
- ❌ No de-duplication of backup events
- ❌ Single point of failure (us-east-1)
- ❌ No automatic failover
- ❌ Missing backup events from us-west-2

## Target Architecture

### Multi-Region Design

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Health Events                           │
│                    (Global + All Regional Events)                   │
└────────────────┬────────────────────────┬─────────────────────────┘
                 │                        │
                 ▼                        ▼
    ┌────────────────────────┐  ┌────────────────────────┐
    │    us-east-1 (Primary) │  │  us-west-2 (Backup)    │
    │  ┌──────────────────┐  │  │  ┌──────────────────┐  │
    │  │   EventBridge    │  │  │  │   EventBridge    │  │
    │  │   Rule (Global   │  │  │  │   Rule           │  │
    │  │   + Regional)    │  │  │  │   (Aggregated)   │  │
    │  └────────┬─────────┘  │  │  └────────┬─────────┘  │
    │           │             │  │           │             │
    │           ▼             │  │           ▼             │
    │  ┌──────────────────┐  │  │  ┌──────────────────┐  │
    │  │  Lambda Function │  │  │  │  Lambda Function │  │
    │  │  (Formatter +    │  │  │  │  (Formatter +    │  │
    │  │   Dedup Logic)   │  │  │  │   Dedup Logic)   │  │
    │  └────────┬─────────┘  │  │  └────────┬─────────┘  │
    │           │             │  │           │             │
    │           └─────────────┼──┼───────────┘             │
    │                         │  │                         │
    │           ┌─────────────▼──▼─────────────┐           │
    │           │   DynamoDB Global Table      │           │
    │           │   (De-duplication Store)     │           │
    │           │   - communicationId (PK)     │           │
    │           │   - timestamp                │           │
    │           │   - TTL (1 hour)             │           │
    │           └─────────────┬────────────────┘           │
    │                         │                            │
    │                         ▼                            │
    │           ┌──────────────────────────┐               │
    │           │      SNS Topic           │               │
    │           │    (us-east-1 Primary)   │               │
    │           └──────────────────────────┘               │
    └─────────────────────────────────────────────────────┘
```

### Key Features
- ✅ **Dual-region deployment:** us-east-1 (primary) + us-west-2 (backup)
- ✅ **Automatic de-duplication:** DynamoDB global table tracking
- ✅ **Global event coverage:** IAM events in us-east-1
- ✅ **Regional aggregation:** All events reach us-west-2
- ✅ **High availability:** Continues if one region fails
- ✅ **Single notification:** De-duplication prevents duplicate alerts

## Implementation Phases

### Phase 1: Foundation - DynamoDB De-duplication Store
**Duration:** 2-3 hours
**Priority:** Critical
**Dependencies:** None

#### Tasks
1. **Create DynamoDB Module** (`modules/dynamodb/`)
   - Global table with replicas in us-east-1 and us-west-2
   - Primary key: `communicationId` (String)
   - TTL attribute: `expirationTime` (Number, 1 hour)
   - Attributes: `timestamp`, `region`, `environment`
   - On-demand billing for cost optimization
   - Point-in-time recovery enabled

2. **Table Schema**
   ```
   communicationId (PK) | timestamp | region | environment | expirationTime (TTL)
   ---------------------|-----------|--------|-------------|---------------------
   arn:aws:health:...   | 170...    | us-e-1 | prod        | 170... (+1hr)
   ```

3. **IAM Permissions**
   - Lambda execution role needs:
     - `dynamodb:PutItem`
     - `dynamodb:GetItem`
     - `dynamodb:Query`
     - Scoped to de-duplication table only

#### Files to Create
```
modules/dynamodb/
├── main.tf           # Global table definition
├── variables.tf      # environment, tags
├── outputs.tf        # table_name, table_arn
└── versions.tf       # Provider requirements
```

#### Success Criteria
- [x] Global table created in both regions
- [x] TTL enabled and functioning
- [x] Can write/read items from both regions
- [x] Replication lag < 1 second

---

### Phase 2: Lambda Enhancement - De-duplication Logic
**Duration:** 2-3 hours
**Priority:** Critical
**Dependencies:** Phase 1 complete

#### Tasks
1. **Update Lambda Function** (`modules/eventbridge/lambda/index.js`)
   - Add AWS SDK v3 DynamoDB client
   - Implement `checkDuplication(communicationId)` function
   - Implement `recordEvent(communicationId, metadata)` function
   - Add error handling for DynamoDB failures
   - Add CloudWatch metrics for duplicates detected
   - Fallback: If DynamoDB unavailable, log and continue

2. **De-duplication Flow**
   ```javascript
   1. Extract communicationId from event.detail
   2. Query DynamoDB for existing record
   3. If found:
      - Log: "Duplicate event detected"
      - Increment CloudWatch metric
      - Return early (skip SNS publish)
   4. If not found:
      - Write record to DynamoDB with TTL
      - Continue with SNS publish
      - Log: "New event processed"
   ```

3. **Environment Variables**
   - Add `DEDUP_TABLE_NAME` to Lambda environment
   - Keep existing `ENVIRONMENT`, `SNS_TOPIC_ARN`

4. **Update Lambda IAM Policy**
   - Add DynamoDB permissions to existing policy
   - Least privilege: Only PutItem, GetItem, Query

#### Code Structure
```javascript
// New imports
const { DynamoDBClient, PutItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');

// Initialize clients
const dynamoClient = new DynamoDBClient({});

// New functions
async function checkDuplication(communicationId) { ... }
async function recordEvent(communicationId, metadata) { ... }

// Updated handler
exports.handler = async (event, context) => {
  const communicationId = event.detail.communicationId;

  // Check for duplicates
  if (await checkDuplication(communicationId)) {
    console.log(`Duplicate event: ${communicationId}`);
    return { statusCode: 200, body: 'Duplicate skipped' };
  }

  // Record event
  await recordEvent(communicationId, { region: event.region, ... });

  // Continue with existing notification logic...
}
```

#### Success Criteria
- [x] Lambda successfully writes to DynamoDB
- [x] Duplicate events are detected and skipped
- [x] CloudWatch metrics show duplicate count
- [x] SNS notifications sent only once per communicationId
- [x] Error handling works when DynamoDB unavailable

---

### Phase 3: Multi-Region Module - EventBridge Deployment
**Duration:** 3-4 hours
**Priority:** High
**Dependencies:** Phase 1, Phase 2 complete

#### Tasks
1. **Create Multi-Region EventBridge Module** (`modules/eventbridge-multiregion/`)
   - Uses Terraform provider aliases for multiple regions
   - Deploys EventBridge rules in both regions
   - Deploys Lambda functions in both regions
   - Configures cross-region DynamoDB access
   - Single SNS topic in us-east-1 (primary)

2. **Provider Configuration**
   ```hcl
   # In environments/{env}/main.tf
   provider "aws" {
     alias  = "us_east_1"
     region = "us-east-1"
   }

   provider "aws" {
     alias  = "us_west_2"
     region = "us-west-2"
   }
   ```

3. **Module Structure**
   ```
   modules/eventbridge-multiregion/
   ├── main.tf
   │   ├── EventBridge rule (us-east-1)
   │   ├── EventBridge rule (us-west-2)
   │   ├── Lambda function (us-east-1)
   │   ├── Lambda function (us-west-2)
   │   ├── IAM roles (both regions)
   │   └── EventBridge targets
   ├── variables.tf
   │   ├── environment
   │   ├── sns_topic_arn
   │   ├── dedup_table_name
   │   └── tags
   ├── outputs.tf
   │   ├── us_east_1_rule_arn
   │   ├── us_west_2_rule_arn
   │   ├── us_east_1_lambda_arn
   │   └── us_west_2_lambda_arn
   └── lambda/ (shared code)
       └── index.js
   ```

4. **EventBridge Event Patterns**
   - us-east-1: Capture all events (global + regional)
   - us-west-2: Capture all events (aggregated from all regions)
   - Both: No `backupEvent` filter (rely on DynamoDB de-duplication)

#### Success Criteria
- [x] EventBridge rules deployed in both regions
- [x] Lambda functions deployed in both regions
- [x] Both Lambdas can access DynamoDB global table
- [x] Both Lambdas can publish to SNS topic
- [x] Only one notification sent regardless of which region processes first

---

### Phase 4: Environment Configuration Updates
**Duration:** 1-2 hours
**Priority:** High
**Dependencies:** Phase 3 complete

#### Tasks
1. **Update Environment Files**
   - Modify `environments/dev/main.tf`
   - Modify `environments/prod/main.tf`
   - Add provider aliases
   - Switch from `eventbridge` module to `eventbridge-multiregion` module
   - Add DynamoDB module instantiation
   - Pass DynamoDB table name to EventBridge module

2. **Migration Strategy**
   - Keep existing single-region module as `eventbridge-singleregion`
   - Create new `eventbridge-multiregion` module
   - Toggle via variable: `enable_multiregion = true/false`
   - Test in dev first, then promote to prod

3. **Terraform State Management**
   - Separate state keys per region
   - Use workspace or separate backend configs
   - Document state migration steps

#### Example Configuration
```hcl
# environments/prod/main.tf

module "dynamodb_dedup" {
  source = "../../modules/dynamodb"

  environment = var.environment
  tags        = local.resource_tags
}

module "eventbridge_multiregion" {
  source = "../../modules/eventbridge-multiregion"

  providers = {
    aws.us_east_1 = aws.us_east_1
    aws.us_west_2 = aws.us_west_2
  }

  environment       = var.environment
  sns_topic_arn     = module.sns.topic_arn
  dedup_table_name  = module.dynamodb_dedup.table_name
  tags              = local.resource_tags
}
```

#### Success Criteria
- [x] Dev environment successfully deploys multi-region setup
- [x] Terraform state properly managed
- [x] No resource conflicts or duplicates
- [x] Existing single-region setup can be rolled back

---

### Phase 5: GitHub Actions Enhancement
**Duration:** 2-3 hours
**Priority:** Medium
**Dependencies:** Phase 4 complete

#### Tasks
1. **Update Workflow** (`.github/workflows/terraform.yml`)
   - Add region selection input
   - Support deploying to multiple regions sequentially
   - Add validation for multi-region state
   - Add rollback mechanism

2. **Workflow Enhancements**
   ```yaml
   workflow_dispatch:
     inputs:
       environment:
         type: choice
         options: ["dev", "prod"]
       deployment_mode:
         type: choice
         description: "Deployment mode"
         options: ["single-region", "multi-region"]
         default: "multi-region"
   ```

3. **Multi-Region Deployment Logic**
   - Initialize Terraform with backend config
   - Plan for all regions
   - Show plan output
   - Require approval for prod
   - Apply to us-east-1 first
   - Apply to us-west-2 second
   - Validate both regions deployed successfully

4. **State Management**
   - Continue using S3 backend with native locking
   - Separate state files per environment (not per region)
   - State includes resources in both regions

#### Success Criteria
- [x] Workflow deploys to both regions successfully
- [x] State properly tracks all resources
- [x] Rollback works correctly
- [x] Clear logs for debugging

---

### Phase 6: Monitoring & Observability
**Duration:** 2-3 hours
**Priority:** Medium
**Dependencies:** Phase 5 complete

#### Tasks
1. **CloudWatch Dashboards**
   - Create multi-region dashboard
   - Metrics per region:
     - EventBridge rule invocations
     - Lambda invocations, errors, duration
     - DynamoDB read/write capacity, throttles
     - SNS publish success/failure
   - Deduplication metrics:
     - Total events received (per region)
     - Duplicate events detected
     - Unique events processed
     - Deduplication rate (%)

2. **CloudWatch Alarms**
   - Lambda errors > 5 in 5 minutes
   - DynamoDB throttling > 0
   - EventBridge rule failures > 0
   - SNS delivery failures > 0
   - Replication lag > 5 seconds
   - Duplicate rate > 50% (indicates issue)

3. **Logging Enhancements**
   - Structured JSON logging in Lambda
   - Log correlation ID (communicationId)
   - Include region in all log messages
   - CloudWatch Insights queries for analysis

4. **Create Monitoring Module** (`modules/monitoring-multiregion/`)
   ```
   modules/monitoring-multiregion/
   ├── main.tf         # Dashboards and alarms
   ├── variables.tf    # Lambda ARNs, table names
   ├── outputs.tf      # Dashboard URLs
   └── dashboards/
       └── health-notifications.json
   ```

#### Success Criteria
- [x] Dashboard shows real-time metrics from both regions
- [x] Alarms trigger on failures
- [x] Logs are searchable and correlated
- [x] Can identify which region processed each event

---

### Phase 7: Testing & Validation
**Duration:** 3-4 hours
**Priority:** Critical
**Dependencies:** All previous phases complete

#### Tasks
1. **Create Test Scripts** (`scripts/testing/`)
   - `test-multiregion-deployment.sh` - Verify deployment
   - `test-deduplication.sh` - Send duplicate events
   - `test-failover.sh` - Simulate region failure
   - `test-health-event-injection.sh` - Inject synthetic events

2. **Test Scenarios**

   **Scenario 1: Normal Operation**
   - Send AWS Health event to us-east-1
   - Verify Lambda processes in us-east-1
   - Verify DynamoDB record created
   - Verify SNS notification sent once
   - Verify us-west-2 receives same event
   - Verify us-west-2 Lambda detects duplicate
   - Verify no second SNS notification

   **Scenario 2: Failover to us-west-2**
   - Disable EventBridge rule in us-east-1
   - Send AWS Health event
   - Verify us-west-2 processes event
   - Verify SNS notification sent
   - Verify DynamoDB record created in us-west-2
   - Re-enable us-east-1 rule
   - Verify system returns to normal

   **Scenario 3: DynamoDB Failure**
   - Simulate DynamoDB throttling
   - Send AWS Health event
   - Verify Lambda handles error gracefully
   - Verify fallback: event still processed (logged as warning)
   - Verify SNS notification still sent

   **Scenario 4: High Volume**
   - Send 100 events simultaneously
   - Verify all events processed exactly once
   - Verify DynamoDB can handle load
   - Verify no throttling or errors

3. **Validation Checklist**
   ```bash
   ✅ Both EventBridge rules are active
   ✅ Both Lambda functions deployed successfully
   ✅ DynamoDB global table replicating correctly
   ✅ SNS topic accessible from both regions
   ✅ De-duplication working (no duplicate notifications)
   ✅ CloudWatch dashboards showing metrics
   ✅ Alarms configured and tested
   ✅ Logs searchable and complete
   ✅ Failover tested and working
   ✅ Documentation updated
   ```

#### Success Criteria
- [x] All test scenarios pass
- [x] No duplicate notifications in any scenario
- [x] Failover works within 1 minute
- [x] System handles 100+ events without errors

---

### Phase 8: Documentation & Runbooks
**Duration:** 2-3 hours
**Priority:** High
**Dependencies:** Phase 7 complete

#### Tasks
1. **Update README.md**
   - Add multi-region architecture diagram (ASCII)
   - Document deployment process
   - Add troubleshooting section
   - Link to monitoring dashboards

2. **Create Runbooks** (`docs/runbooks/`)
   - `incident-response.md` - How to respond to failures
   - `failover-procedure.md` - Manual failover steps
   - `rollback-procedure.md` - How to rollback to single-region
   - `monitoring-guide.md` - Dashboard interpretation

3. **Update deployment.md**
   - Multi-region deployment commands
   - State management guidelines
   - Testing procedures

4. **Architecture Documentation**
   - Data flow diagrams
   - Failure scenarios and responses
   - Cost analysis (single vs. multi-region)
   - Performance benchmarks

5. **Update CLAUDE.md**
   - Add multi-region deployment standards
   - Document module usage patterns
   - Testing requirements

#### Success Criteria
- [x] All documentation complete and accurate
- [x] Runbooks tested with actual scenarios
- [x] Team trained on multi-region operations
- [x] Knowledge base searchable

---

## Timeline & Effort Estimate

| Phase | Duration | Dependencies | Priority | Status |
|-------|----------|--------------|----------|--------|
| 1. DynamoDB Foundation | 2-3 hours | None | Critical | Not Started |
| 2. Lambda Enhancement | 2-3 hours | Phase 1 | Critical | Not Started |
| 3. Multi-Region Module | 3-4 hours | Phase 1, 2 | High | Not Started |
| 4. Environment Updates | 1-2 hours | Phase 3 | High | Not Started |
| 5. GitHub Actions | 2-3 hours | Phase 4 | Medium | Not Started |
| 6. Monitoring | 2-3 hours | Phase 5 | Medium | Not Started |
| 7. Testing | 3-4 hours | All | Critical | Not Started |
| 8. Documentation | 2-3 hours | Phase 7 | High | Not Started |

**Total Estimated Time:** 17-25 hours
**Recommended Approach:** 3-4 day sprint with 2 engineers

---

## Risk Assessment & Mitigation

### High Risk
**Risk:** DynamoDB replication lag causes duplicate notifications
**Mitigation:**
- Set TTL to 1 hour (much longer than typical lag)
- Add retry logic with exponential backoff
- Monitor replication lag with CloudWatch alarms

**Risk:** Both regions fail simultaneously
**Mitigation:**
- Document manual recovery procedure
- Keep single-region module as fallback
- Test rollback procedures regularly

### Medium Risk
**Risk:** Increased costs from multi-region deployment
**Mitigation:**
- Use on-demand DynamoDB pricing
- Monitor costs with AWS Cost Explorer
- Set budget alerts

**Risk:** Complex state management causes deployment failures
**Mitigation:**
- Test extensively in dev environment
- Document state migration clearly
- Have rollback plan ready

### Low Risk
**Risk:** Lambda timeout with DynamoDB check
**Mitigation:**
- Set appropriate timeout (30s is sufficient)
- Implement DynamoDB query timeout
- Add fallback to process even if DynamoDB fails

---

## Cost Analysis

### Current Single-Region Setup (Estimated Monthly)
- EventBridge: $1.00 (per million events)
- Lambda: $0.20 (minimal invocations)
- SNS: $0.50 (per million notifications)
- S3 (state): $0.10
- **Total: ~$1.80/month**

### Multi-Region Setup (Estimated Monthly)
- EventBridge (2 regions): $2.00
- Lambda (2 regions): $0.40
- DynamoDB Global Table: $5.00 (on-demand, assuming 1000 events/month)
- SNS: $0.50
- S3 (state): $0.10
- CloudWatch (dashboards): $3.00
- **Total: ~$11.00/month**

**Increase:** ~$9.20/month (~$110/year)
**Justification:** High availability for critical health notifications

---

## Rollback Plan

If multi-region deployment causes issues:

1. **Immediate Rollback** (5 minutes)
   ```bash
   # Disable us-west-2 EventBridge rule
   aws events disable-rule --name prod-health-event-notifications --region us-west-2

   # Continue using us-east-1 only
   ```

2. **Full Rollback to Single Region** (30 minutes)
   ```bash
   # Switch environment to use single-region module
   cd environments/prod
   # Edit main.tf to use eventbridge module instead of eventbridge-multiregion
   terraform plan
   terraform apply
   ```

3. **DynamoDB Table Cleanup** (if needed)
   - Table can remain (minimal cost)
   - Or delete after confirming rollback successful

---

## Success Metrics

### Technical Metrics
- **Uptime:** 99.9% availability across both regions
- **De-duplication Rate:** 100% (no duplicate notifications)
- **Failover Time:** < 1 minute to detect and route to backup region
- **Replication Lag:** < 1 second average

### Business Metrics
- **MTTR (Mean Time to Recovery):** < 5 minutes
- **Alert Delivery:** 100% of AWS Health events result in notification
- **False Positives:** 0 duplicate alerts to subscribers
- **Cost Efficiency:** < $15/month for multi-region setup

---

## Next Steps

1. **Review this plan** with the team
2. **Approve budget** for multi-region deployment
3. **Assign tasks** from Phase 1
4. **Set up dev environment** for testing
5. **Begin Phase 1** - DynamoDB implementation
6. **Schedule daily standups** during implementation
7. **Plan production cutover** after successful dev testing

---

## Questions & Decisions Needed

- [ ] **Budget Approval:** Is ~$110/year acceptable for high availability?
- [ ] **Testing Window:** When can we test failover in production?
- [ ] **Notification Strategy:** Should we alert on failover events?
- [ ] **Monitoring Access:** Who needs access to CloudWatch dashboards?
- [ ] **On-Call Rotation:** Who responds to multi-region alerts?

---

## References

- [AWS Health Documentation](https://docs.aws.amazon.com/health/latest/ug/choosing-a-region.html)
- [DynamoDB Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html)
- [EventBridge Multi-Region](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-cross-region.html)
- [Lambda Multi-Region Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-13
**Author:** AWS Health Notifications Team
**Status:** Draft - Pending Approval
