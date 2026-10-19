data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name_prefix        = "${var.cluster_name}-node-"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json

  tags = var.tags
}

locals {
  node_policies = concat(
    [
      "arn:${local.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:${local.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:${local.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    ],
    var.enable_ssm ? ["arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"] : [],
  )
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset(local.node_policies)

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_launch_template" "node" {
  #checkov:skip=CKV_AWS_341:Hop limit is a variable; 2 is the EKS default so pods without Pod Identity still get instance metadata.
  name_prefix            = "${var.cluster_name}-node-"
  update_default_version = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.node_metadata_hop_limit
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.cluster_name}-node" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.cluster_name}-node" })
  }

  tags = var.tags
}

resource "aws_eks_node_group" "default" {
  cluster_name           = aws_eks_cluster.this.name
  node_group_name_prefix = "${var.cluster_name}-default-"
  node_role_arn          = aws_iam_role.node.arn
  subnet_ids             = var.subnet_ids

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  labels         = var.node_labels

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_eks_addon.before_nodes,
  ]
}
