variables {
  queue_name_prefix = "lab3-test-defaults"
  # enable_dlq defaults to true in the module
  # tags defaults to {} in the module
}

run "plan_default_settings" {
  # command = plan is the default, so it's optional here

  check "plan_produces_changes" {
    assert {
      # Verify that the plan is not empty
      condition     = length(resource_changes) > 0
      error_message = "Plan should propose at least one resource change with default settings."
    }
  }
}

run "apply_and_check_outputs" {
  command = apply

  check "outputs_are_valid" {
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
}

run "plan_dlq_disabled" {
  # Override variables specifically for this run
  variables {
    queue_name_prefix = "lab3-test-no-dlq"
    enable_dlq        = false # Disable the DLQ for this test case
  }

  check "plan_creates_correct_resources" {
    assert {
      # Check that the DLQ resource change is absent
      condition     = !anytrue([for rc in resource_changes : rc.address == "module.test.aws_sqs_queue.dlq"])
      # Note: The address includes 'module.test' because terraform test wraps the module under test.
      error_message = "DLQ resource should not be present in the plan when enable_dlq is false."
    }
     assert {
       # Check that the main queue and KMS key *are* present
       condition = anytrue([for rc in resource_changes : rc.address == "module.test.aws_sqs_queue.main"]) && \
                   anytrue([for rc in resource_changes : rc.address == "module.test.aws_kms_key.sqs_key"])
       error_message = "Main queue and KMS key should be present in the plan."
     }
  }
}

run "apply_dlq_disabled_outputs" {
  command = apply

  # We need to reference the variables defined in the preceding run block.
  # Terraform test currently reuses the *last specified* variables block if a run block
  # doesn't define its own. So, this run will correctly use enable_dlq = false.
  # Be mindful of this behavior in complex tests.

  check "outputs_reflect_dlq_disabled" {
    assert {
      condition     = output.dlq_arn == null
      error_message = "DLQ ARN output should be null when enable_dlq is false."
    }
    assert {
      condition     = output.main_queue_arn != null # Main queue should still exist
      error_message = "Main queue ARN should still be present."
    }
  }
}

run "fail_on_empty_prefix" {
  variables {
    queue_name_prefix = "" # Invalid input
    enable_dlq        = false # Keep other variables consistent if needed
  }

  # command = plan is default

  # Expect the plan to fail with the specific validation error message
  expect_failures = [
    var.queue_name_prefix.validation[0].error_message,
    # Can reference module variable validation messages directly.
  ]
}