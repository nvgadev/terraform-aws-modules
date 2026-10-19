mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  repositories = ["insurequote/quote-api", "insurequote/web"]
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = length(aws_ecr_repository.this) == 2
    error_message = "Expected one repository per name."
  }

  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.image_tag_mutability == "IMMUTABLE"])
    error_message = "Tags must be immutable by default."
  }

  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.image_scanning_configuration[0].scan_on_push])
    error_message = "Scan on push must be on by default."
  }

  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.encryption_configuration[0].encryption_type == "KMS"])
    error_message = "Repositories must be KMS encrypted."
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 2
    error_message = "Every repository needs a lifecycle policy."
  }

  assert {
    condition     = length(aws_ecr_repository_policy.pull) == 0
    error_message = "No repository policy unless pull principals are given."
  }
}

run "cross_account_pull" {
  command = plan

  variables {
    pull_principal_arns = ["arn:aws:iam::111122223333:root"]
  }

  assert {
    condition     = length(aws_ecr_repository_policy.pull) == 2
    error_message = "Each repository should get a pull policy."
  }
}

run "rejects_uppercase_name" {
  command = plan

  variables {
    repositories = ["InsureQuote/API"]
  }

  expect_failures = [var.repositories]
}
