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
}

provider "aws" {
  region = "us-west-2" // Or your preferred region
}

module "secure_queue_test" {
  source = "./modules/sqs-secure" # Relative path to local module

  queue_name_prefix = "adv-tf-lab2-test"
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