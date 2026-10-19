output "repository_urls" {
  description = "Map of repository name to repository URL (use as the image name when pushing)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  description = "Map of repository name to ARN (use in IAM push/pull policies)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}

output "registry_id" {
  description = "Registry (account) ID that holds the repositories."
  value       = try(one(distinct([for repo in aws_ecr_repository.this : repo.registry_id])), null)
}
