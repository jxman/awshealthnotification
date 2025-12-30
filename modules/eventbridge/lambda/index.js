// Lambda function to format AWS Health event notifications with enhanced plain text
// Updated for nodejs22.x with AWS SDK v3
// Force deployment: 2025-12-30T00:00:00Z
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');

// Initialize SNS client - AWS Lambda automatically provides region
const snsClient = new SNSClient({});

exports.handler = async (event, context) => {
  console.log('Event received:', JSON.stringify(event, null, 2));
  console.log('Lambda runtime:', process.version);

  try {
    // Validate event structure
    if (!event.detail) {
      throw new Error('Invalid event structure: missing detail object');
    }

    // Extract relevant information from the event
    const service = event.detail.service || 'Unknown';
    const status = event.detail.statusCode || 'Unknown';
    const eventType = event.detail.eventTypeCode || 'Unknown';
    const category = event.detail.eventTypeCategory || 'Unknown';
    const description = event.detail.eventDescription?.[0]?.latestDescription || 'No description available';
    const eventArn = event.detail.eventArn || 'Unknown';
    const startTime = event.detail.startTime || 'Unknown';
    const endTime = event.detail.endTime || 'Unknown';
    const eventTime = event.time || 'Unknown';
    const region = event.region || 'Unknown';
    const account = event.account || 'Unknown';
    const environment = process.env.ENVIRONMENT || 'UNKNOWN';

    // Get status emoji
    const statusEmoji = getStatusEmoji(status);

    // Create enhanced plain text message
    const enhancedMessage = formatHealthEvent({
      statusEmoji, environment, service, status, eventType, category,
      eventTime, startTime, endTime, description, eventArn, region, account
    });

    // Create a subject line
    const subject = `${statusEmoji} ${environment} ALERT: ${service} ${status.toUpperCase()} - ${eventType}`;

    // Publish to SNS using AWS SDK v3
    const command = new PublishCommand({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: subject,
      Message: enhancedMessage
    });

    const result = await snsClient.send(command);
    console.log('Message published successfully:', result);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Notification sent successfully',
        messageId: result.MessageId,
        runtime: process.version,
        environment
      })
    };
  } catch (error) {
    console.error('Error processing health event:', error);

    // Send fallback notification
    try {
      await sendFallbackNotification(error, event);
    } catch (fallbackError) {
      console.error('Failed to send fallback notification:', fallbackError);
    }

    throw error;
  }
};

function getStatusEmoji(status) {
  const statusMap = {
    'closed': '✅',
    'open': '⚠️',
    'upcoming': '📅'
  };
  return statusMap[status.toLowerCase()] || '🔔';
}

function formatHealthEvent(params) {
  const { statusEmoji, environment, service, status, eventType, category,
          eventTime, startTime, endTime, description, eventArn, region, account } = params;

  return `
=====================================================================
            ${statusEmoji}  AWS HEALTH EVENT - ${environment} ENVIRONMENT  ${statusEmoji}
=====================================================================

📊  EVENT SUMMARY
    -------------------------------------------------------------
    • Service:    ${service}
    • Status:     ${status.toUpperCase()}
    • Type:       ${eventType}
    • Category:   ${category}

🕒  TIMELINE
    -------------------------------------------------------------
    • Detected:   ${eventTime}
    • Started:    ${startTime}
    • Ended:      ${endTime}

📝  DESCRIPTION
    -------------------------------------------------------------
    ${description}

🔍  EVENT DETAILS
    -------------------------------------------------------------
    • Event ARN:  ${eventArn}
    • Region:     ${region}
    • Account:    ${account}

=====================================================================
                 AWS HEALTH EVENT MONITORING SYSTEM
=====================================================================`;
}

async function sendFallbackNotification(error, originalEvent) {
  try {
    const fallbackMessage = `
⚠️ AWS Health Event Processing Error
Environment: ${process.env.ENVIRONMENT}
Runtime: ${process.version}
Error: ${error.message}
Timestamp: ${new Date().toISOString()}

Original Event Summary:
${JSON.stringify(originalEvent, null, 2)}
    `;

    const command = new PublishCommand({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: `🚨 ${process.env.ENVIRONMENT} - Lambda Processing Error`,
      Message: fallbackMessage
    });

    await snsClient.send(command);
    console.log('Fallback notification sent');
  } catch (fallbackError) {
    console.error('Failed to send fallback notification:', fallbackError);
  }
}
