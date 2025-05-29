# S3 backend configuration for production environment
# This matches the GitHub Actions workflow configuration pattern
bucket       = "jxman-terraform-state-bucket"
key          = "health-notifications/prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
