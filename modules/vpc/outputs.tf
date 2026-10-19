output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "azs" {
  description = "Availability zones used, in subnet order."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers, NAT gateways)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes, RDS)."
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  description = "Private route table IDs, one per AZ (for gateway VPC endpoints)."
  value       = aws_route_table.private[*].id
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways (allow-list these for outbound traffic)."
  value       = aws_eip.nat[*].public_ip
}

output "flow_log_group_name" {
  description = "CloudWatch log group for flow logs, or null when disabled."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}
