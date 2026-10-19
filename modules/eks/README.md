# EKS

EKS cluster with access entries (API auth mode), KMS-encrypted secrets, control-plane logs, a managed node group on a hardened launch template, and the core add-ons, including the EBS CSI driver through EKS Pod Identity.

## Usage

```hcl
module "eks" {
  source = "git::https://github.com/nvgadev/terraform-aws-modules.git//modules/eks?ref=eks-v1.0.0"

  cluster_name        = "insurequote-demo"
  kubernetes_version  = "1.34"
  subnet_ids          = module.vpc.private_subnet_ids
  public_access_cidrs = ["203.0.113.10/32"]

  admin_principal_arns = [
    "arn:aws:iam::111122223333:role/AWSReservedSSO_AdministratorAccess_abc123",
  ]
}
```

A runnable example is in [`examples/basic`](examples/basic).

## Notes

- `kubernetes_version` has no default on purpose: pick one in standard support with `aws eks describe-cluster-versions`.
- The creator gets no hidden admin rights; everyone who needs `kubectl` is listed in `admin_principal_arns`.
- For IAM Identity Center roles, use the role ARN **without** the `/aws-reserved/sso.amazonaws.com/` path.
- Nodes require IMDSv2 and use encrypted gp3 root volumes; reach them with SSM Session Manager, not SSH.
- `support_type = "STANDARD"` avoids the extended-support surcharge.
- The control plane costs about $73/month while it exists; destroy demo clusters when idle.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| aws | >= 6.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0, < 7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_access_entry.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_addon.before_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cluster_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.pod_identity_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | EKS cluster name; also the prefix for its IAM roles and node group. | `string` | n/a | yes |
| kubernetes\_version | Kubernetes minor version, for example "1.34". Pick one in standard support: aws eks describe-cluster-versions --query 'clusterVersions[?versionStatus==`STANDARD_SUPPORT`].clusterVersion'. | `string` | n/a | yes |
| subnet\_ids | Private subnet IDs (at least two AZs) for the control plane ENIs and nodes. | `list(string)` | n/a | yes |
| addon\_versions | Optional pinned add-on versions, keyed by add-on name. Unlisted add-ons use the default version for the cluster. | `map(string)` | `{}` | no |
| admin\_principal\_arns | IAM role or user ARNs given cluster-admin through EKS access entries (for example your SSO role and the CI apply role). | `list(string)` | `[]` | no |
| cluster\_log\_retention\_days | CloudWatch retention for control plane logs, in days. | `number` | `30` | no |
| cluster\_log\_types | Control plane log types sent to CloudWatch. | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator"<br/>]</pre> | no |
| create\_kms\_key | Create a KMS key for Kubernetes secrets encryption. Ignored when kms\_key\_arn is set. | `bool` | `true` | no |
| enable\_ebs\_csi\_driver | Install the EBS CSI driver add-on with a Pod Identity role. | `bool` | `true` | no |
| enable\_ssm | Attach AmazonSSMManagedInstanceCore so nodes can be reached with Session Manager instead of SSH. | `bool` | `true` | no |
| endpoint\_public\_access | Expose the Kubernetes API publicly (restricted to public\_access\_cidrs). The private endpoint is always on. | `bool` | `true` | no |
| kms\_key\_arn | Existing KMS key ARN for secrets encryption. | `string` | `null` | no |
| node\_ami\_type | EKS AMI type. Use AL2023\_ARM\_64\_STANDARD for Graviton (t4g, m7g) instances. | `string` | `"AL2023_x86_64_STANDARD"` | no |
| node\_capacity\_type | ON\_DEMAND or SPOT. | `string` | `"ON_DEMAND"` | no |
| node\_desired\_size | Desired nodes at creation. Later changes by an autoscaler are ignored. | `number` | `2` | no |
| node\_disk\_size\_gb | Root volume size for each node, in GiB. | `number` | `30` | no |
| node\_instance\_types | Instance types for the managed node group. Several types improve Spot availability. | `list(string)` | <pre>[<br/>  "t3.large"<br/>]</pre> | no |
| node\_labels | Kubernetes labels for the nodes. | `map(string)` | `{}` | no |
| node\_max\_size | Maximum nodes. | `number` | `3` | no |
| node\_metadata\_hop\_limit | IMDSv2 hop limit. 1 blocks pods from the node's instance credentials; 2 lets pods without Pod Identity read instance metadata. | `number` | `2` | no |
| node\_min\_size | Minimum nodes. | `number` | `1` | no |
| public\_access\_cidrs | CIDRs allowed to reach the public API endpoint, for example your home IP as x.x.x.x/32. | `list(string)` | `[]` | no |
| support\_type | STANDARD makes AWS auto-upgrade at end of standard support instead of billing for extended support. | `string` | `"STANDARD"` | no |
| tags | Tags added to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_arn | EKS cluster ARN. |
| cluster\_certificate\_authority\_data | Base64 cluster CA certificate, for kubeconfig and the kubernetes/helm providers. |
| cluster\_endpoint | Kubernetes API endpoint. |
| cluster\_name | EKS cluster name. |
| cluster\_security\_group\_id | Security group EKS created for the control plane and managed nodes (allow it in RDS and other services). |
| cluster\_version | Kubernetes version running on the control plane. |
| kms\_key\_arn | KMS key used for Kubernetes secrets encryption. |
| kubeconfig\_command | Command to add this cluster to your kubeconfig. |
| node\_group\_name | Name of the default managed node group. |
| node\_role\_arn | IAM role used by the managed nodes. |
| oidc\_issuer\_url | Cluster OIDC issuer URL (only needed if you later add IRSA). |
<!-- END_TF_DOCS -->
