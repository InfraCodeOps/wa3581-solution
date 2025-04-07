terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
     # Random provider needed by module via S3 bucket name
    random = {
      source = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  # Add terraform cloud block for registry access if needed,
  # but login context should typically suffice
  # cloud {
  #   organization = "<YOUR_ORG_NAME>" # Replace with your HCP Org Name
  #   workspaces {
  #     tags = ["lab4-test"] # Optional
  #   }
  # }
}

provider "aws" {
  region = "us-west-2" // Or your preferred region
}

module "secure_queue_test" {
  # Updated source to use HCP Private Registry
  # !!! Instructor Note: Replace <YOUR_ORG_NAME> with the actual org name students use !!!
  source  = "app.terraform.io/<YOUR_ORG_NAME>/sqs-secure/aws"
  version = "~> 1.0.0" # Use version constraint matching the tag created

  queue_name_prefix = "adv-tf-lab4-registry-test" # Use a different prefix for clarity
  
  enable_dlq        = true # Explicitly enable for testing
  tags = {
    Environment = "lab2-test"
    Project     = "Advanced TF Course"
  }
}

output "test_main_queue_arn" {
  description = "Output from the test module call: Main Queue ARN"
  value       = module.secure_queue_test.main_queue_arn
}

output "test_main_queue_url" {
  description = "Output from the test module call: Main Queue URL"
  value       = module.secure_queue_test.main_queue_url
}

output "test_dlq_arn" {
  description = "Output from the test module call: DLQ ARN"
  value       = module.secure_queue_test.dlq_arn
}

output "test_kms_key_arn" {
  description = "Output from the test module call: KMS Key ARN"
  value       = module.secure_queue_test.kms_key_arn
}