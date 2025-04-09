variables {
  queue_name_prefix = "lab03-test-defaults"
  # enable_dlq defaults to true in the module
  # tags defaults to {} in the module
}

# Simple test to ensure plan works properly
run "plan_default_settings" {
  command = plan
  # No assert needed; success means plan executes without errors
}

# Test to ensure ARNs are being assigned correctly
run "apply_and_check_outputs" {
  command = apply

  assert {
    condition     = output.main_queue_arn != null && substr(output.main_queue_arn, 0, 12) == "arn:aws:sqs:"
    error_message = "Main queue ARN should be a valid SQS ARN."
  }
  assert {
    condition     = output.kms_key_arn != null && substr(output.kms_key_arn, 0, 12) == "arn:aws:kms:"
    error_message = "KMS key ARN should be a valid KMS ARN."
  }
  assert {
    # DLQ is enabled by default, so its ARN should be present
    condition     = output.dlq_arn != null && substr(output.dlq_arn, 0, 12) == "arn:aws:sqs:"
    error_message = "DLQ ARN should be a valid SQS ARN when DLQ is enabled."
  }
  # Could also add checks for main_queue_url format if needed

}

# Test to ensure DLQ is not created when enable_dlq is false
run "apply_dlq_disabled" {
  command = apply
  # Override variables specifically for this run
  variables {
    queue_name_prefix = "lab03-test-no-dlq"
    enable_dlq        = false # Disable the DLQ for this test case
  }
  assert {
    # Check that given count is zero, the list of dlq objects should be empty
    condition     = length(aws_sqs_queue.dlq) == 0
    error_message = "DLQ should be an empty list when enable_dlq is false"
  }
  assert {
    # Check that the output.dlq_arn is not set
    condition     = output.dlq_arn == null
    error_message = "DLQ ARN output should be null when enable_dlq is false."
  }
  assert {
    # Check that the main queue is still present
    condition     = aws_sqs_queue.main.name == "lab03-test-no-dlq"
    error_message = "Main queue should be created with correct name"
  }
  assert {
    # Check that the KMS key is still present
    condition     = aws_kms_key.sqs_key.arn != null
    error_message = "KMS key should be created"
  }
}

run "fail_on_empty_prefix" {
  variables {
    queue_name_prefix = "" # Invalid input
  }
  command = plan

  # Test succeeds if validation for queue_name_prefix errors out
  expect_failures = [
    var.queue_name_prefix
  ]
}