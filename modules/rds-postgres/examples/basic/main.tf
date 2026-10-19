provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../../vpc"

  name = "iq-rds-example"
}

module "db" {
  source = "../.."

  identifier          = "insurequote-demo"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  db_name         = "insurequote"
  master_username = "iq_admin"

  tags = {
    project    = "insurequote"
    env        = "demo"
    managed-by = "terraform"
  }
}

output "db_address" {
  value = module.db.address
}

output "db_secret_arn" {
  value = module.db.master_user_secret_arn
}
