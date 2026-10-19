# VPC

Two- or three-AZ VPC with public and private /20 subnets, NAT (single by default to save cost), a locked-down default security group, EKS subnet tags and optional VPC Flow Logs.

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/nvgadev/terraform-aws-modules.git//modules/vpc?ref=vpc-v1.0.0"

  name             = "insurequote-demo"
  az_count         = 2
  eks_cluster_name = "insurequote-demo"
}
```

A runnable example is in [`examples/basic`](examples/basic).

## Notes

- The default security group has no rules, so nothing silently uses it.
- Public subnets do not auto-assign public IPs.
- `single_nat_gateway = true` costs about $32/month plus data; set it to false for one NAT per AZ.

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
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.flow_logs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for every resource in the VPC. | `string` | n/a | yes |
| az\_count | Number of availability zones to spread subnets across. | `number` | `2` | no |
| cidr\_block | IPv4 CIDR for the VPC. Each subnet gets a /20 carved from it, so use a /16. | `string` | `"10.20.0.0/16"` | no |
| eks\_cluster\_name | If set, subnets get the kubernetes.io/cluster/<name> tag used by EKS load balancer discovery. | `string` | `null` | no |
| enable\_flow\_logs | Send VPC flow logs (all traffic) to CloudWatch Logs. | `bool` | `false` | no |
| enable\_nat\_gateway | Create NAT gateways so private subnets can reach the internet. | `bool` | `true` | no |
| flow\_logs\_kms\_key\_arn | Optional KMS key ARN to encrypt the flow log group. Uses CloudWatch's default encryption when null. | `string` | `null` | no |
| flow\_logs\_retention\_days | CloudWatch retention for flow logs, in days. | `number` | `30` | no |
| single\_nat\_gateway | Use one shared NAT gateway instead of one per AZ. Cheaper; loses AZ redundancy. | `bool` | `true` | no |
| tags | Tags added to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| azs | Availability zones used, in subnet order. |
| flow\_log\_group\_name | CloudWatch log group for flow logs, or null when disabled. |
| nat\_public\_ips | Public IPs of the NAT gateways (allow-list these for outbound traffic). |
| private\_route\_table\_ids | Private route table IDs, one per AZ (for gateway VPC endpoints). |
| private\_subnet\_ids | Private subnet IDs (EKS nodes, RDS). |
| public\_subnet\_ids | Public subnet IDs (load balancers, NAT gateways). |
| vpc\_cidr\_block | CIDR block of the VPC. |
| vpc\_id | ID of the VPC. |
<!-- END_TF_DOCS -->
