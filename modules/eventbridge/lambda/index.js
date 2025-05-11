// Lambda function to format AWS Health event notifications with enhanced plain text
exports.handler = async (event) => {
  console.log('Event received:', JSON.stringify(event, null, 2));
  
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
  const statusEmoji = status === 'closed' ? '✅' : status === 'open' ? '⚠️' : '🔔';
  
  // Create enhanced plain text message (without box borders)
  const enhancedMessage = `
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

  // Create a subject line
  const subject = `${statusEmoji} ${environment} ALERT: ${service} ${status.toUpperCase()} - ${eventType}`;

  // Publish to SNS
  const AWS = require('aws-sdk');
  const sns = new AWS.SNS();
  
  const params = {
    TopicArn: process.env.SNS_TOPIC_ARN,
    Subject: subject,
    Message: enhancedMessage
  };
  
  try {
    const result = await sns.publish(params).promise();
    console.log('Message published:', result);
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Notification sent successfully', messageId: result.MessageId })
    };
  } catch (error) {
    console.error('Error publishing message:', error);
    throw error;
  }
};
