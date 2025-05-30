# Development environment configuration
aws_region  = "us-east-1"
environment = "dev"
github_org  = "xman"
github_repo = "aws-health-notifications"
owner_team  = "platform-team"
cost_center = "platform-engineering"

tags = {
  Environment = "dev"
  Service     = "aws-health-notifications"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
  Project     = "health-monitoring"
  Application = "aws-health-notifications"
  Criticality = "medium"
  Backup      = "false"
  Compliance  = "none"
}
