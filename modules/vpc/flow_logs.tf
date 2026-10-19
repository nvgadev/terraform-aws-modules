resource "aws_cloudwatch_log_group" "flow_logs" {
  #checkov:skip=CKV_AWS_158:KMS is optional via flow_logs_kms_key_arn; CloudWatch encrypts at rest by default.
  #checkov:skip=CKV_AWS_338:Retention is configurable; 30 days keeps demo costs low.
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.flow_logs_kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "flow_logs_assume" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix        = "${substr(var.name, 0, 20)}-flowlogs-"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "flow_logs_write" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_logs[0].arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name   = "write-flow-logs"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_write[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn

  tags = merge(var.tags, { Name = var.name })
}
