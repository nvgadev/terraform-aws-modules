output "role_arn" {
  description = "Role ARN to pass to aws-actions/configure-aws-credentials as role-to-assume."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Role name."
  value       = aws_iam_role.this.name
}

output "subjects" {
  description = "OIDC subjects the role trusts."
  value       = var.subjects
}
