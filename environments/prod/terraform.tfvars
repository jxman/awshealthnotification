# Production environment configuration
aws_region  = "us-east-1"
environment = "prod"
github_org  = "xman"
github_repo = "aws-health-notifications"
owner_team  = "platform-team"
cost_center = "platform-engineering"

tags = {
  Environment = "prod"
  Service     = "aws-health-notifications"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
  Project     = "health-monitoring"
  Application = "aws-health-notifications"
  Criticality = "high"
  Backup      = "true"
  Compliance  = "none"
}
