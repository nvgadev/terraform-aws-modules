# terraform-aws-modules

Reusable, tested Terraform modules for AWS, built for the **InsureQuote** DevOps + AI portfolio and usable in any project.

[![ci](https://github.com/nvgadev/terraform-aws-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/nvgadev/terraform-aws-modules/actions/workflows/ci.yml)

| Module | What it builds | Latest |
|---|---|---|
| [`vpc`](modules/vpc) | Multi-AZ VPC, public/private subnets, NAT, optional Flow Logs | `vpc-v1.0.0` |
| [`eks`](modules/eks) | EKS with access entries, KMS secrets, hardened managed nodes, Pod Identity add-ons | `eks-v1.0.0` |
| [`ecr`](modules/ecr) | Immutable, scanned, encrypted ECR repositories with lifecycle rules | `ecr-v1.0.0` |
| [`rds-postgres`](modules/rds-postgres) | Private, encrypted PostgreSQL with Secrets Manager password and IAM auth | `rds-postgres-v1.0.0` |
| [`iam-github-oidc`](modules/iam-github-oidc) | Keyless GitHub Actions → AWS role via OIDC | `iam-github-oidc-v1.0.0` |

## Usage

Pin every module to its own release tag:

```hcl
module "vpc" {
  source = "git::https://github.com/nvgadev/terraform-aws-modules.git//modules/vpc?ref=vpc-v1.0.0"

  name = "my-app"
}
```

Requirements: Terraform >= 1.10 (or OpenTofu >= 1.10) and the AWS provider 6.x. Each module's README lists its inputs and outputs.

## How quality is enforced

Every pull request runs, per module:

| Check | Tool |
|---|---|
| Formatting | `terraform fmt -check` |
| Syntax and types | `terraform validate` (module and its example) |
| Behaviour | `terraform test` with a **mock AWS provider**, so tests are free and need no credentials |
| Lint and AWS rules | `tflint` with the AWS ruleset |
| Security misconfigurations | Checkov (every skip is commented inline with a reason) |
| Docs in sync | `terraform-docs` regenerates READMEs and fails on drift |

A separate job assumes a read-only AWS role through **GitHub OIDC** to prove keyless access works; no AWS keys are stored in this repository.

## Local development

```bash
cd modules/vpc
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform test

# from the repo root
tflint --init --config=.tflint.hcl
tflint --chdir=modules/vpc --config="$PWD/.tflint.hcl"
checkov -d modules --framework terraform --quiet --compact
for m in modules/*/; do terraform-docs -c .terraform-docs.yml "$m"; done
```

Optional: `pre-commit install` runs the same checks before each commit (see `.pre-commit-config.yaml`).

## Releasing

Each module is versioned on its own with [SemVer](https://semver.org) tags named `<module>-vMAJOR.MINOR.PATCH`:

- **PATCH** — fixes with no input or output changes
- **MINOR** — new optional inputs or new outputs
- **MAJOR** — removed or renamed inputs/outputs, or changes that replace resources

```bash
git checkout main && git pull
git tag -a vpc-v1.1.0 -m "vpc: add IPv6 option"
git push origin vpc-v1.1.0
gh release create vpc-v1.1.0 --title "vpc v1.1.0" --notes "Adds IPv6 option."
```

## License

[MIT](LICENSE)
