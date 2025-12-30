/**
 * # EventBridge Health Notifications Module
 *
 * This module creates an EventBridge rule that captures AWS Health Events and routes them
 * through a Lambda function for formatting before sending to an SNS topic.
 *
 * ## Features
 *
 * - **EventBridge Rule**: Captures all AWS Health Events from aws.health source
 * - **Lambda Formatter**: Node.js 22.x function that formats events into human-readable notifications
 * - **Environment Control**: Enable/disable notifications per environment without destroying resources
 * - **CloudWatch Logs**: Full logging integration for Lambda execution
 * - **Least-Privilege IAM**: Minimal permissions for Lambda execution (SNS publish + CloudWatch Logs)
 * - **Auto-Deployment**: Lambda code changes automatically detected and deployed via source hash
 *
 * ## Event Flow
 *
 * ```
 * AWS Health Events → EventBridge Rule → Lambda Function → SNS Topic → Subscribers
 * ```
 *
 * ## Lambda Function
 *
 * The Lambda function (Node.js 22.x) enhances AWS Health Event notifications with:
 * - Formatted event summaries with severity indicators
 * - Affected resource details
 * - Event timeline information
 * - Action recommendations
 *
 * Lambda code is located in `./lambda/` and automatically packaged as a ZIP file with
 * change detection based on source hash.
 */

resource "aws_cloudwatch_event_rule" "health_events" {
  name        = "${var.environment}-health-event-notifications"
  description = "Captures AWS Health Events for ${var.environment}"
  state       = var.enabled ? "ENABLED" : "DISABLED"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = merge(
    var.tags,
    {
      Name       = "${var.environment}-health-event-rule"
      SubService = "health-event-rule"
    }
  )
}

# Define local variables for tags
locals {
  resource_tags = merge(
    {
      Name        = "${var.environment}-health-event-notifications"
      Environment = var.environment
      Service     = "aws-health-notifications"
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Create a ZIP file for the Lambda function with proper change detection
data "archive_file" "lambda_zip" {
  type             = "zip"
  output_path      = "${path.module}/lambda_function.zip"
  output_file_mode = "0666"

  # Use source_dir to include all files in the lambda directory
  source_dir = "${path.module}/lambda"

  # Add excludes to prevent unwanted files
  excludes = [
    "*.pyc",
    "__pycache__",
    ".DS_Store",
    "*.swp",
    "*.tmp",
    "*-debug.js", # Exclude debug files
    "*.test.js",  # Exclude test files
    "*.spec.js",  # Exclude spec files
    "README.md",  # Exclude documentation
    ".gitignore"  # Exclude git files
  ]
}

# Create the Lambda function with enhanced change detection
resource "aws_lambda_function" "health_formatter" {
  function_name = "${var.environment}-health-event-formatter"
  description   = "Formats AWS Health Events into enhanced notifications for SNS distribution"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  timeout       = 30
  memory_size   = 128

  # Reference the ZIP file created by the archive_file data source
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Publish a new version when code changes
  publish = true

  environment {
    variables = {
      ENVIRONMENT   = upper(var.environment)
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = merge(
    local.resource_tags,
    {
      Name       = "${var.environment}-health-event-formatter"
      SubService = "health-event-formatter-lambda"
    }
  )
}

# Create the IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name        = "${var.environment}-health-formatter-role"
  description = "Execution role for health event formatter Lambda function with SNS publish and CloudWatch Logs permissions"

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

  tags = merge(
    local.resource_tags,
    {
      Name       = "${var.environment}-health-formatter-role"
      SubService = "lambda-execution-role"
    }
  )
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
        Effect   = "Allow"
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
        Effect   = "Allow"
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
