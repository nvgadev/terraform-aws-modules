locals {
  oidc_host = "token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "trust" {
  #checkov:skip=CKV_AWS_358:False positive on GitHub immutable subjects (owner@id/repo@id); variable validation rejects repo:* and non-repo claims.
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = [var.audience]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values   = var.subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
