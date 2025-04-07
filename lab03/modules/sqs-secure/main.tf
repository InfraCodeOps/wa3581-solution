resource "aws_kms_key" "sqs_key" {
  description             = "KMS key for encrypting ${var.queue_name_prefix} SQS queues"
  enable_key_rotation = true
  tags                  = var.tags
}

resource "aws_sqs_queue" "dlq" {
  # Create this resource only if enable_dlq is true
  count = var.enable_dlq ? 1 : 0

  name              = "${var.queue_name_prefix}-dlq"
  kms_master_key_id = aws_kms_key.sqs_key.arn
  tags              = var.tags
  # Consider adding message retention period, etc.
}

resource "aws_sqs_queue" "main" {
  name              = var.queue_name_prefix
  kms_master_key_id = aws_kms_key.sqs_key.arn

  # Configure redrive policy ONLY if DLQ is enabled
  # Note: Using dynamic configuration or conditional logic avoids errors when DLQ is disabled.
  # Here, we use a conditional expression for the attribute value.
  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn # Access the single DLQ instance ARN
    maxReceiveCount     = 5
  }) : null # Set to null if DLQ is disabled

  tags = var.tags
  # Consider adding other queue attributes like visibility_timeout_seconds
}