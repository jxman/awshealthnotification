// Lambda function to format AWS Health event notifications with HTML email
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
  
  // Get status color and icon
  const statusColor = status === 'closed' ? '#2ea043' : status === 'open' ? '#d13212' : '#0969da';
  const statusIcon = status === 'closed' ? '✅' : status === 'open' ? '⚠️' : '🔔';
  
  // Create HTML formatted email
  const htmlMessage = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 0; background-color: #f5f5f5; }
    .container { max-width: 700px; margin: 0 auto; background-color: #ffffff; padding: 20px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
    .header { background-color: #232F3E; color: white; padding: 15px; text-align: center; margin: -20px -20px 20px -20px; border-radius: 5px 5px 0 0; }
    .footer { background-color: #232F3E; color: white; padding: 15px; text-align: center; margin: 20px -20px -20px -20px; border-radius: 0 0 5px 5px; font-size: 14px; }
    .section { background-color: #f8f9fa; padding: 15px; margin-bottom: 20px; border-left: 5px solid #FF9900; }
    .section h2 { margin-top: 0; color: #232F3E; font-size: 18px; }
    .details { display: grid; grid-template-columns: 150px 1fr; gap: 10px; }
    .label { font-weight: bold; color: #555; text-align: right; }
    .value { color: #333; }
    .status { font-weight: bold; padding: 5px 10px; border-radius: 3px; color: white; background-color: ${statusColor}; display: inline-block; }
    .description { background-color: #fff; padding: 15px; border: 1px solid #ddd; border-radius: 3px; margin-top: 10px; }
    .arn { font-family: monospace; word-break: break-all; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${statusIcon} AWS Health Event</h1>
      <p>${environment} Environment</p>
    </div>
    
    <div class="section">
      <h2>📊 Event Summary</h2>
      <div class="details">
        <div class="label">Service:</div>
        <div class="value"><strong>${service}</strong></div>
        
        <div class="label">Status:</div>
        <div class="value"><span class="status">${status.toUpperCase()}</span></div>
        
        <div class="label">Type:</div>
        <div class="value">${eventType}</div>
        
        <div class="label">Category:</div>
        <div class="value">${category}</div>
      </div>
    </div>
    
    <div class="section">
      <h2>🕒 Timeline</h2>
      <div class="details">
        <div class="label">Detected:</div>
        <div class="value">${eventTime}</div>
        
        <div class="label">Started:</div>
        <div class="value">${startTime}</div>
        
        <div class="label">Ended:</div>
        <div class="value">${endTime}</div>
      </div>
    </div>
    
    <div class="section">
      <h2>📝 Description</h2>
      <div class="description">
        ${description}
      </div>
    </div>
    
    <div class="section">
      <h2>🔍 Event Details</h2>
      <div class="details">
        <div class="label">Event ARN:</div>
        <div class="value arn">${eventArn}</div>
        
        <div class="label">Region:</div>
        <div class="value">${region}</div>
        
        <div class="label">Account:</div>
        <div class="value">${account}</div>
      </div>
    </div>
    
    <div class="footer">
      AWS Health Event Monitoring System
    </div>
  </div>
</body>
</html>`;

  // Create plain text version as fallback
  const plainTextMessage = `
AWS HEALTH EVENT - ${environment} ENVIRONMENT
============================================

EVENT SUMMARY:
- Service:    ${service}
- Status:     ${status.toUpperCase()}
- Type:       ${eventType}
- Category:   ${category}

TIMELINE:
- Detected:   ${eventTime}
- Started:    ${startTime}
- Ended:      ${endTime}

DESCRIPTION:
${description}

EVENT DETAILS:
- Event ARN:  ${eventArn}
- Region:     ${region}
- Account:    ${account}

============================================
AWS HEALTH EVENT MONITORING SYSTEM`;

  // Create a subject line
  const subject = `${environment} ALERT: ${service} ${status.toUpperCase()} - ${eventType}`;

  // Publish to SNS with HTML formatting
  const AWS = require('aws-sdk');
  const sns = new AWS.SNS();
  
  const params = {
    TopicArn: process.env.SNS_TOPIC_ARN,
    Subject: subject,
    Message: JSON.stringify({
      default: plainTextMessage,
      email: htmlMessage
    }),
    MessageStructure: 'json'
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
