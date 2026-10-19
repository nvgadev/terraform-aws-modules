mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name              = "iq-gha-test"
  oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
  subjects          = ["repo:nvgadev@192898833/insurequote-platform@1416259552:ref:refs/heads/main"]
}

run "role_with_managed_and_inline_policies" {
  command = plan

  variables {
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    inline_policy_json  = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }

  assert {
    condition     = aws_iam_role.this.name == "iq-gha-test" && aws_iam_role.this.max_session_duration == 3600
    error_message = "Role name or session duration is wrong."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 1 && length(aws_iam_role_policy.inline) == 1
    error_message = "Expected one managed attachment and one inline policy."
  }
}

run "no_inline_policy_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy.inline) == 0 && length(aws_iam_role_policy_attachment.managed) == 0
    error_message = "No policies should be attached unless asked for."
  }
}

run "rejects_wildcard_owner" {
  command = plan

  variables {
    subjects = ["repo:*"]
  }

  expect_failures = [var.subjects]
}

run "rejects_non_github_provider" {
  command = plan

  variables {
    oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/accounts.google.com"
  }

  expect_failures = [var.oidc_provider_arn]
}
