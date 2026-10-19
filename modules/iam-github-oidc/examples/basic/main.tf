provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Role that lets the app repo push images to ECR from main, using GitHub's
# immutable subject format (owner and repo IDs included).
module "ecr_push_role" {
  source = "../.."

  name              = "iq-gha-ecr-push"
  description       = "insurequote-platform main branch pushes images to ECR."
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"

  subjects = [
    "repo:nvgadev@192898833/insurequote-platform@1416259552:ref:refs/heads/main",
  ]

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetAuthToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "PushInsureQuoteImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/insurequote/*"
      },
    ]
  })

  tags = {
    project    = "insurequote"
    managed-by = "terraform"
  }
}

output "role_arn" {
  value = module.ecr_push_role.role_arn
}
