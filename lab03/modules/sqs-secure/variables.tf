variable "queue_name_prefix" {
  type        = string
  description = "Prefix for the SQS queue names (e.g., 'app-prod'). Will be used for main and DLQ if enabled."

  validation {
    condition     = length(var.queue_name_prefix) > 0
    error_message = "The queue_name_prefix must not be empty."
  }
}

variable "enable_dlq" {
  type        = bool
  description = "Set to true to create a Dead Letter Queue alongside the main SQS queue."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to the SQS queues and KMS key."
  default     = {}
}