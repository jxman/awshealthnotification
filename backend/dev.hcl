bucket         = "jxman-terraform-state-bucket"
key            = "health-notifications/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
