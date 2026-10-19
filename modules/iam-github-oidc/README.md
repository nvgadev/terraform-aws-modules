# IAM role for GitHub Actions (OIDC)

IAM role that GitHub Actions assumes through OIDC, so workflows get short-lived AWS credentials with no stored keys.

## Usage

```hcl
module "deploy_role" {
  source = "git::https://github.com/nvgadev/terraform-aws-modules.git//modules/iam-github-oidc?ref=iam-github-oidc-v1.0.0"

  name              = "iq-gha-ecr-push"
  oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"

  # GitHub immutable subject: owner@owner_id/repo@repo_id
  subjects = [
    "repo:nvgadev@192898833/insurequote-platform@1416259552:ref:refs/heads/main",
  ]

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"]
}
```

A runnable example is in [`examples/basic`](examples/basic).

## Notes

- Subjects must start with `repo:` and may not be `repo:*`.
- GitHub sends immutable subjects (`owner@id/repo@id`). Get the IDs with `gh api repos/OWNER/REPO --jq '.owner.id, .id'`.
- The workflow needs `permissions: id-token: write`.

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
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | IAM role name. | `string` | n/a | yes |
| oidc\_provider\_arn | ARN of the existing token.actions.githubusercontent.com OIDC provider in this account. | `string` | n/a | yes |
| subjects | OIDC subject patterns allowed to assume the role (StringLike, so * is a wildcard).<br/>Name format:      repo:OWNER/REPO:ref:refs/heads/main<br/>Immutable format: repo:OWNER@OWNER\_ID/REPO@REPO\_ID:environment:demo<br/>Check which one a repo uses before choosing. | `list(string)` | n/a | yes |
| audience | Expected token audience. configure-aws-credentials uses sts.amazonaws.com. | `string` | `"sts.amazonaws.com"` | no |
| description | IAM role description. | `string` | `"Assumed by GitHub Actions through OIDC."` | no |
| inline\_policy\_json | Optional inline policy document (JSON). | `string` | `null` | no |
| managed\_policy\_arns | Managed policy ARNs to attach. | `list(string)` | `[]` | no |
| max\_session\_duration | Maximum session length in seconds (3600-43200). | `number` | `3600` | no |
| permissions\_boundary\_arn | Optional permissions boundary for the role. | `string` | `null` | no |
| tags | Tags added to the role. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role\_arn | Role ARN to pass to aws-actions/configure-aws-credentials as role-to-assume. |
| role\_name | Role name. |
| subjects | OIDC subjects the role trusts. |
<!-- END_TF_DOCS -->
