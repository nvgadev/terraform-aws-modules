output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 cluster CA certificate, for kubeconfig and the kubernetes/helm providers."
  value       = one(aws_eks_cluster.this.certificate_authority[*].data)
}

output "cluster_version" {
  description = "Kubernetes version running on the control plane."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Security group EKS created for the control plane and managed nodes (allow it in RDS and other services)."
  value       = one(aws_eks_cluster.this.vpc_config[*].cluster_security_group_id)
}

output "oidc_issuer_url" {
  description = "Cluster OIDC issuer URL (only needed if you later add IRSA)."
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}

output "node_role_arn" {
  description = "IAM role used by the managed nodes."
  value       = aws_iam_role.node.arn
}

output "node_group_name" {
  description = "Name of the default managed node group."
  value       = aws_eks_node_group.default.node_group_name
}

output "kms_key_arn" {
  description = "KMS key used for Kubernetes secrets encryption."
  value       = local.kms_key_arn
}

output "kubeconfig_command" {
  description = "Command to add this cluster to your kubeconfig."
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region <region>"
}
