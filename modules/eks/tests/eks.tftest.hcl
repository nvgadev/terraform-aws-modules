mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/iq-test-role"
    }
  }

  mock_resource "aws_launch_template" {
    defaults = {
      id             = "lt-0123456789abcdef0"
      latest_version = 1
    }
  }

  mock_resource "aws_eks_cluster" {
    defaults = {
      arn = "arn:aws:eks:us-east-1:111122223333:cluster/iq-test"
    }
  }
}

variables {
  cluster_name        = "iq-test"
  kubernetes_version  = "1.34"
  subnet_ids          = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  public_access_cidrs = ["203.0.113.10/32"]
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API"
    error_message = "Access must use EKS access entries (API mode)."
  }

  assert {
    condition     = aws_eks_cluster.this.access_config[0].bootstrap_cluster_creator_admin_permissions == false
    error_message = "The creator must not get hidden admin; admins are explicit access entries."
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access
    error_message = "Private endpoint must be on."
  }

  assert {
    condition     = length(aws_kms_key.secrets) == 1 && aws_kms_key.secrets[0].enable_key_rotation
    error_message = "A rotating KMS key should be created for secrets encryption."
  }

  assert {
    condition     = aws_eks_cluster.this.upgrade_policy[0].support_type == "STANDARD"
    error_message = "Clusters should not slide into paid extended support by default."
  }

  assert {
    condition     = aws_launch_template.node.metadata_options[0].http_tokens == "required"
    error_message = "Nodes must require IMDSv2."
  }

  assert {
    condition     = aws_launch_template.node.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "Node root volumes must be encrypted."
  }

  assert {
    condition     = length(aws_eks_addon.before_nodes) == 3 && length(aws_eks_addon.ebs_csi) == 1
    error_message = "Expected vpc-cni, kube-proxy, pod identity agent and the EBS CSI driver."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.node) == 4
    error_message = "Node role should have worker, CNI, ECR read and SSM policies."
  }
}

run "admins_and_spot" {
  command = plan

  variables {
    admin_principal_arns  = ["arn:aws:iam::111122223333:role/admin", "arn:aws:iam::111122223333:role/ci"]
    node_capacity_type    = "SPOT"
    enable_ssm            = false
    enable_ebs_csi_driver = false
  }

  assert {
    condition     = length(aws_eks_access_entry.admin) == 2 && length(aws_eks_access_policy_association.admin) == 2
    error_message = "Each admin principal needs an access entry and a policy association."
  }

  assert {
    condition     = aws_eks_node_group.default.capacity_type == "SPOT"
    error_message = "Node group should use Spot."
  }

  assert {
    condition     = length(aws_eks_addon.ebs_csi) == 0 && length(aws_iam_role_policy_attachment.node) == 3
    error_message = "EBS CSI and SSM should be off."
  }
}

run "existing_kms_key" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = length(aws_kms_key.secrets) == 0
    error_message = "No key should be created when one is supplied."
  }
}

run "rejects_open_public_endpoint" {
  command = plan

  variables {
    public_access_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.public_access_cidrs]
}

run "rejects_bad_node_sizes" {
  command = plan

  variables {
    node_min_size     = 3
    node_desired_size = 1
  }

  expect_failures = [var.node_max_size]
}
