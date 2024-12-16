terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0" # Specify a fixed minor version for stability
    }
  }
  required_version = ">= 1.0.0"

  backend "s3" {}
}
