provider "aws" {
  region = "us-east-1"
}

module "ecr" {
  source = "../.."

  repositories = [
    "insurequote/web",
    "insurequote/quote-api",
    "insurequote/policy-service",
    "insurequote/notification-worker",
  ]

  # Demo environment is destroyed nightly, so allow deleting repos that hold images.
  force_delete = true

  tags = {
    project    = "insurequote"
    env        = "demo"
    managed-by = "terraform"
  }
}

output "repository_urls" {
  value = module.ecr.repository_urls
}
