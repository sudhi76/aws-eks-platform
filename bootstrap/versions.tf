terraform {
  required_version = ">= 1.10"

  # Local state: this stack creates the bucket every other stack keeps its state in.
  # After the first apply it can be migrated into that bucket (see README).

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
      Project   = "aws-eks-platform"
      Stack     = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}
