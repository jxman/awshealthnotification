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
    "*.tmp"
  ]
}

# Create the Lambda function with enhanced change detection
resource "aws_lambda_function" "health_formatter" {
  function_name = "${var.environment}-health-event-formatter"
  description   = "Formats AWS Health Events into enhanced notifications for SNS distribution"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 128

  # Reference the ZIP file created by the archive_file data source
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Publish a new version when code changes
  publish = true

  # Ensure Lambda updates when code changes
  depends_on = [null_resource.lambda_trigger]

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

# Data source for current AWS region
data "aws_region" "current" {}

# Null resource to trigger Lambda updates when source code changes
resource "null_resource" "lambda_trigger" {
  # This will change whenever the Lambda source code changes
  triggers = {
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    lambda_file_hash = filebase64sha256("${path.module}/lambda/index.js")
  }

  # Optional: Clean up old ZIP files
  provisioner "local-exec" {
    command = "find ${path.module} -name 'lambda_function_*.zip' -type f -not -name '${basename(data.archive_file.lambda_zip.output_path)}' -delete || true"
  }
}
