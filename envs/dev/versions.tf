terraform {
  required_version = ">= 1.10"

  # Partial configuration: bucket, key and region come from backend.hcl at init.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "aws-eks-platform"
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}
