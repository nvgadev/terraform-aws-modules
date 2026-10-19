# ECR

ECR repositories that are immutable, scanned on push, KMS-encrypted and cleaned by a lifecycle policy, with optional cross-account pull access.

## Usage

```hcl
module "ecr" {
  source = "git::https://github.com/nvgadev/terraform-aws-modules.git//modules/ecr?ref=ecr-v1.0.0"

  repositories = ["insurequote/api", "insurequote/web"]
}
```

A runnable example is in [`examples/basic`](examples/basic).

## Notes

- Tags are IMMUTABLE by default, so a deployed tag always means the same image.
- Untagged images expire after 7 days and only the last 30 tagged images are kept.

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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_policy_document.pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repositories | Repository names to create, for example ["insurequote/quote-api"]. | `set(string)` | n/a | yes |
| force\_delete | Allow terraform destroy to delete repositories that still contain images. Handy for throwaway demo environments. | `bool` | `false` | no |
| image\_tag\_mutability | IMMUTABLE (recommended) stops a tag from being overwritten. | `string` | `"IMMUTABLE"` | no |
| kms\_key\_arn | Customer managed KMS key for image encryption. When null, the AWS managed aws/ecr key is used. | `string` | `null` | no |
| max\_tagged\_images | Keep this many most recent tagged images per repository; older ones expire. | `number` | `30` | no |
| pull\_principal\_arns | Extra IAM principal ARNs (for example other accounts) allowed to pull images. Same-account roles need only IAM permissions. | `list(string)` | `[]` | no |
| scan\_on\_push | Run ECR basic vulnerability scanning when an image is pushed. | `bool` | `true` | no |
| tags | Tags added to every repository. | `map(string)` | `{}` | no |
| untagged\_expiry\_days | Delete untagged images after this many days. | `number` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry\_id | Registry (account) ID that holds the repositories. |
| repository\_arns | Map of repository name to ARN (use in IAM push/pull policies). |
| repository\_urls | Map of repository name to repository URL (use as the image name when pushing). |
<!-- END_TF_DOCS -->
