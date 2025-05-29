# S3 backend configuration for development environment
# This matches the GitHub Actions workflow configuration pattern
# Update the bucket name to match your TF_STATE_BUCKET secret in GitHub
bucket       = "jxman-terraform-state-bucket"
key          = "health-notifications/dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
