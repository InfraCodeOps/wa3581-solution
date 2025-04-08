terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  # Backend configured by HCP Workspace
}

# Variables will be populated by HCP Workspace Variables
variable "queue_prefix" {
  type        = string
  description = "Prefix for queue names, provided by workspace."
}

variable "environment_tag" {
  type        = string
  description = "Tag value for the Environment tag, provided by workspace."
}

provider "aws" {
  region = "us-west-2"
}

module "dev_queue" {
  # !!! Instructor Note: Replace <YOUR_ORG_NAME> with the actual org name students use !!!
  source  = "app.terraform.io/<YOUR_ORG_NAME>/sqs-secure/aws"
  version = "~> 1.0.0" # Use constraint matching published version

  queue_name_prefix = var.queue_prefix # From workspace variable
  enable_dlq        = true             # Keep DLQ enabled for dev

  tags = {
    Project         = "Advanced TF Course"
    Environment     = var.environment_tag # From workspace variable
    GitOpsManaged   = "true" # <<< Added Tag during Lab 6
  }
}

# Optional: Define outputs if needed for cross-workspace dependencies later
# output "dev_queue_arn" { value = module.dev_queue.main_queue_arn }