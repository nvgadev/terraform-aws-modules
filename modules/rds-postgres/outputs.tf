output "instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.identifier
}

output "instance_arn" {
  description = "RDS instance ARN."
  value       = aws_db_instance.this.arn
}

output "address" {
  description = "Hostname of the database."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master user name."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN holding the master password (managed and rotated by RDS)."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}

output "security_group_id" {
  description = "Security group attached to the database."
  value       = aws_security_group.this.id
}

output "resource_id" {
  description = "DbiResourceId, used in rds-db:connect IAM policies for IAM authentication."
  value       = aws_db_instance.this.resource_id
}
