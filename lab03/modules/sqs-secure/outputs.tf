output "main_queue_arn" {
  description = "The ARN of the main SQS queue."
  value       = aws_sqs_queue.main.arn
}

output "main_queue_url" {
  description = "The URL of the main SQS queue."
  value       = aws_sqs_queue.main.id # URL is stored in the 'id' attribute for SQS queue
}

output "dlq_arn" {
  description = "The ARN of the Dead Letter Queue (DLQ), if created."
  # Use try() to gracefully return null if the DLQ doesn't exist (count=0)
  value       = try(aws_sqs_queue.dlq[0].arn, null)
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for queue encryption."
  value       = aws_kms_key.sqs_key.arn
}