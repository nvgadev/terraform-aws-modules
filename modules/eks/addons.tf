# Networking add-ons go in before nodes so new nodes join with the managed versions.
resource "aws_eks_addon" "before_nodes" {
  for_each = toset(["vpc-cni", "kube-proxy", "eks-pod-identity-agent"])

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  addon_version               = lookup(var.addon_versions, each.value, null)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

# CoreDNS needs nodes to schedule on.
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  addon_version               = lookup(var.addon_versions, "coredns", null)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.default]
}

# ---------------------------------------------------------------------------
# EBS CSI driver with a Pod Identity role (no node-wide EBS permissions)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "pod_identity_assume" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name_prefix        = "${substr(var.cluster_name, 0, 24)}-ebs-csi-"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = lookup(var.addon_versions, "aws-ebs-csi-driver", null)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  pod_identity_association {
    role_arn        = aws_iam_role.ebs_csi[0].arn
    service_account = "ebs-csi-controller-sa"
  }

  tags = var.tags

  depends_on = [
    aws_eks_node_group.default,
    aws_eks_addon.before_nodes,
    aws_iam_role_policy_attachment.ebs_csi,
  ]
}
