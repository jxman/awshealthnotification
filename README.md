## Managing Subscriptions

SNS topic subscriptions are managed manually through the AWS Console, not through Terraform. This approach provides more flexibility and avoids issues with subscription confirmation and state management.

### Adding Email Subscriptions

1. Navigate to the AWS SNS Console
2. Find the topic: `{environment}-health-event-notifications`
3. Click "Create subscription"
4. Choose:
   - Protocol: Email
   - Endpoint: Enter the email address
5. Click "Create subscription"
6. Check the email inbox and confirm the subscription

### Adding SMS Subscriptions

1. Navigate to the AWS SNS Console
2. Find the topic: `{environment}-health-event-notifications`
3. Click "Create subscription"
4. Choose:
   - Protocol: SMS
   - Endpoint: Enter the phone number in E.164 format (e.g., +14155551234)
5. Click "Create subscription"

### Managing Existing Subscriptions

1. Go to the SNS topic in AWS Console
2. Click on the "Subscriptions" tab
3. You can:
   - Delete subscriptions
   - View delivery status
   - Check subscription attributes

### Benefits of Manual Management

- No Terraform state issues with confirmations
- Easy to add/remove subscriptions without code changes
- No deployment required for subscription changes
- Avoid issues with phone number formatting in code
- Team members can manage their own subscriptions
