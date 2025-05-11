resource "aws_cloudwatch_event_rule" "health_events" {
  name        = "${var.environment}-health-event-notifications"
  description = "Captures AWS Health Events for ${var.environment}"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
}

# Create the Lambda function
resource "aws_lambda_function" "health_formatter" {
  function_name = "${var.environment}-health-event-formatter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 128

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT    = upper(var.environment)
      SNS_TOPIC_ARN  = var.sns_topic_arn
    }
  }

  tags = var.tags
}

# Create a ZIP file for the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  
  source {
    content  = file("${path.module}/lambda/index.js")
    filename = "index.js"
  }
}

# Create the IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-health-formatter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach the SNS publish policy to the Lambda role
resource "aws_iam_role_policy" "lambda_sns_policy" {
  name = "${var.environment}-health-formatter-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish"
        ]
        Effect = "Allow"
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Attach CloudWatch Logs policy to the Lambda role
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "${var.environment}-health-formatter-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Set the Lambda as the EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.health_events.name
  target_id = "HealthEventLambdaTarget"
  arn       = aws_lambda_function.health_formatter.arn
}

# Give EventBridge permission to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_formatter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_events.arn
}
