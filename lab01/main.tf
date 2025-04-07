terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" // Use an appropriate AWS provider version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Backend is configured implicitly by HCP Terraform Workspace
}

provider "aws" {
  region = "us-east-1" // Or your preferred AWS region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "learning_bucket" {
  bucket = "tf-adv-lab1-${random_string.suffix.result}" # Construct unique name

  tags = {
    Name        = "TF Advanced Lab 1 Bucket"
    Environment = "learning" # Includes the tag added via CLI workflow
  }
}