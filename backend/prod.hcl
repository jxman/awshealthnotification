# S3 backend with native locking (use_lockfile = true)
bucket       = "jxman-terraform-state-bucket"
key          = "health-notifications/prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
