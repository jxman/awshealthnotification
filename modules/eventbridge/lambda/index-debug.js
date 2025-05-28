// Simplified Lambda function for nodejs20.x troubleshooting
// This version uses minimal dependencies to isolate issues

exports.handler = async (event, context) => {
  console.log('🚀 Lambda function started');
  console.log('Runtime:', process.version);
  console.log('Event received:', JSON.stringify(event, null, 2));
  
  try {
    // Test AWS SDK v3 import
    console.log('📦 Testing AWS SDK import...');
    const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
    console.log('✅ AWS SDK v3 imported successfully');
    
    // Initialize SNS client
    const snsClient = new SNSClient({});
    console.log('✅ SNS Client initialized');
    
    // Validate event structure
    if (!event.detail) {
      throw new Error('Invalid event structure: missing detail object');
    }

    // Extract basic information
    const service = event.detail.service || 'Unknown';
    const status = event.detail.statusCode || 'Unknown';
    const environment = process.env.ENVIRONMENT || 'UNKNOWN';
    
    console.log(`Processing: ${service} - ${status} in ${environment}`);
    
    // Create simple message
    const message = `
🔔 AWS Health Event - ${environment}

Service: ${service}
Status: ${status}
Runtime: ${process.version}
Timestamp: ${new Date().toISOString()}

This is a test notification from the updated Lambda function.
    `;

    const subject = `${environment} Health Alert: ${service} ${status}`;
    
    // Test SNS publish
    console.log('📤 Publishing to SNS...');
    const command = new PublishCommand({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: subject,
      Message: message
    });
    
    const result = await snsClient.send(command);
    console.log('✅ Message published successfully:', result.MessageId);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ 
        message: 'Notification sent successfully', 
        messageId: result.MessageId,
        runtime: process.version,
        environment: environment,
        service: service,
        status: status
      })
    };
    
  } catch (error) {
    console.error('❌ Error in Lambda function:', error);
    console.error('Error stack:', error.stack);
    
    // Return error details for debugging
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: error.message,
        runtime: process.version,
        timestamp: new Date().toISOString()
      })
    };
  }
};
