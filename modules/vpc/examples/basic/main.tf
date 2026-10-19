provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../.."

  name             = "insurequote-demo"
  cidr_block       = "10.20.0.0/16"
  az_count         = 2
  eks_cluster_name = "insurequote-demo"
  enable_flow_logs = true

  tags = {
    project    = "insurequote"
    env        = "demo"
    managed-by = "terraform"
  }
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
