provider "aws" {
  region = "us-east-1"
}

variable "my_ip_cidr" {
  description = "Your public IP as x.x.x.x/32 (curl -s https://checkip.amazonaws.com)."
  type        = string
}

variable "sso_admin_role_arn" {
  description = "Your IAM Identity Center role ARN (aws sts get-caller-identity, converted to the role ARN)."
  type        = string
}

module "vpc" {
  source = "../../../vpc"

  name             = "insurequote-demo"
  eks_cluster_name = "insurequote-demo"
}

module "eks" {
  source = "../.."

  cluster_name       = "insurequote-demo"
  kubernetes_version = "1.34"
  subnet_ids         = module.vpc.private_subnet_ids

  public_access_cidrs = [var.my_ip_cidr]

  admin_principal_arns = [
    var.sso_admin_role_arn,
    "arn:aws:iam::352329340795:role/iq-gha-apply",
  ]

  node_instance_types = ["t3.large", "t3a.large"]
  node_capacity_type  = "SPOT"

  tags = {
    project    = "insurequote"
    env        = "demo"
    managed-by = "terraform"
  }
}

output "kubeconfig_command" {
  value = module.eks.kubeconfig_command
}
