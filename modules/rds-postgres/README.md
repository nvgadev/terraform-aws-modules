# RDS PostgreSQL

Private, encrypted RDS for PostgreSQL with the master password kept in Secrets Manager, IAM database authentication, CloudWatch log exports and a security group that only admits the callers you list.

## Usage

```hcl
module "db" {
  source = "git::https://github.com/nvgadev/terraform-aws-modules.git//modules/rds-postgres?ref=rds-postgres-v1.0.0"

  identifier                 = "insurequote-demo"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
}
```

A runnable example is in [`examples/basic`](examples/basic).

## Notes

- No password appears in Terraform state: RDS generates it and stores it in Secrets Manager (`master_user_secret_arn`).
- Defaults suit a cheap demo (db.t4g.micro, single-AZ, no deletion protection). For anything real, set `multi_az`, `deletion_protection` and `skip_final_snapshot = false`.

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
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.from_cidrs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_policy_document.monitoring_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| identifier | RDS instance identifier; also the prefix for the subnet group and security group. | `string` | n/a | yes |
| subnet\_ids | Private subnet IDs (at least two AZs) for the DB subnet group. | `list(string)` | n/a | yes |
| vpc\_id | VPC for the database security group. | `string` | n/a | yes |
| allocated\_storage | Initial storage in GiB. | `number` | `20` | no |
| allowed\_cidr\_blocks | CIDR blocks allowed to connect on the PostgreSQL port. Keep to private ranges. | `list(string)` | `[]` | no |
| allowed\_security\_group\_ids | Security groups allowed to connect on the PostgreSQL port (for example the EKS node or pod security group). | `list(string)` | `[]` | no |
| backup\_retention\_days | Days to keep automated backups (0 disables them). | `number` | `1` | no |
| db\_name | Name of the initial database. | `string` | `"app"` | no |
| deletion\_protection | Block deletion of the instance. Turn on for anything long-lived. | `bool` | `false` | no |
| engine\_version | PostgreSQL major version (AWS picks the default minor) or a full version string. | `string` | `"17"` | no |
| instance\_class | Instance class. Burstable classes keep the demo cheap. | `string` | `"db.t4g.micro"` | no |
| kms\_key\_arn | KMS key for storage, Performance Insights and the master secret. AWS managed keys are used when null. | `string` | `null` | no |
| master\_username | Master user name. Its password is generated and kept in Secrets Manager by RDS. | `string` | `"app_admin"` | no |
| max\_allocated\_storage | Storage autoscaling ceiling in GiB. Set equal to allocated\_storage to disable autoscaling. | `number` | `50` | no |
| monitoring\_interval | Enhanced Monitoring interval in seconds (0 disables it; 60 is the cheapest when on). | `number` | `0` | no |
| multi\_az | Run a standby in a second AZ. | `bool` | `false` | no |
| performance\_insights\_enabled | Enable Performance Insights. Off by default: not every small instance class supports it. | `bool` | `false` | no |
| skip\_final\_snapshot | Skip the final snapshot on destroy. True suits throwaway demo environments. | `bool` | `true` | no |
| tags | Tags added to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| address | Hostname of the database. |
| db\_name | Initial database name. |
| instance\_arn | RDS instance ARN. |
| instance\_id | RDS instance identifier. |
| master\_user\_secret\_arn | Secrets Manager ARN holding the master password (managed and rotated by RDS). |
| master\_username | Master user name. |
| port | Database port. |
| resource\_id | DbiResourceId, used in rds-db:connect IAM policies for IAM authentication. |
| security\_group\_id | Security group attached to the database. |
<!-- END_TF_DOCS -->
