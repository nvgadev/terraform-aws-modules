data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  partition   = data.aws_partition.current.partition
  account_id  = data.aws_caller_identity.current.account_id
  kms_key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.secrets[0].arn
}

# ---------------------------------------------------------------------------
# Secrets encryption key
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "kms" {
  #checkov:skip=CKV_AWS_109:Key policies must use Resource "*" (the key itself).
  #checkov:skip=CKV_AWS_111:Key policies must use Resource "*" (the key itself).
  #checkov:skip=CKV_AWS_356:Key policies must use Resource "*" (the key itself).
  count = var.kms_key_arn == null && var.create_kms_key ? 1 : 0

  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "secrets" {
  count = var.kms_key_arn == null && var.create_kms_key ? 1 : 0

  description             = "EKS secrets encryption for ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms[0].json

  tags = var.tags
}

resource "aws_kms_alias" "secrets" {
  count = var.kms_key_arn == null && var.create_kms_key ? 1 : 0

  name          = "alias/eks/${var.cluster_name}"
  target_key_id = aws_kms_key.secrets[0].key_id
}

# ---------------------------------------------------------------------------
# Control plane
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name_prefix        = "${var.cluster_name}-cluster-"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Created up front so retention is set before EKS starts writing logs.
resource "aws_cloudwatch_log_group" "cluster" {
  #checkov:skip=CKV_AWS_158:CloudWatch encrypts at rest; a CMK here needs a logs service grant on the key.
  #checkov:skip=CKV_AWS_338:Retention is configurable; 30 days keeps demo costs low.
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = var.tags
}

resource "aws_eks_cluster" "this" {
  #checkov:skip=CKV_AWS_37:Log types are a variable; api, audit and authenticator by default for cost.
  #checkov:skip=CKV_AWS_38:Public access is limited to public_access_cidrs; 0.0.0.0/0 is rejected by validation.
  #checkov:skip=CKV_AWS_39:Public endpoint is optional and CIDR-restricted for a laptop-driven demo.
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.cluster_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = local.kms_key_arn
    }
  }

  upgrade_policy {
    support_type = var.support_type
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

# ---------------------------------------------------------------------------
# Who can administer the cluster (access entries, no aws-auth ConfigMap)
# ---------------------------------------------------------------------------
resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
