variable "name" {
  description = "IAM role name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.name))
    error_message = "name must be a valid IAM role name (1-64 characters)."
  }
}

variable "description" {
  description = "IAM role description."
  type        = string
  default     = "Assumed by GitHub Actions through OIDC."
}

variable "oidc_provider_arn" {
  description = "ARN of the existing token.actions.githubusercontent.com OIDC provider in this account."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:oidc-provider/token\\.actions\\.githubusercontent\\.com$", var.oidc_provider_arn))
    error_message = "oidc_provider_arn must be the ARN of the GitHub Actions OIDC provider."
  }
}

variable "subjects" {
  description = <<-EOT
    OIDC subject patterns allowed to assume the role (StringLike, so * is a wildcard).
    Name format:      repo:OWNER/REPO:ref:refs/heads/main
    Immutable format: repo:OWNER@OWNER_ID/REPO@REPO_ID:environment:demo
    Check which one a repo uses before choosing.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subjects) > 0 && alltrue([for s in var.subjects : startswith(s, "repo:") && !startswith(s, "repo:*")])
    error_message = "Each subject must start with repo:OWNER and must not wildcard the owner."
  }
}

variable "audience" {
  description = "Expected token audience. configure-aws-credentials uses sts.amazonaws.com."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy document (JSON)."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary for the role."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session length in seconds (3600-43200)."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200."
  }
}

variable "tags" {
  description = "Tags added to the role."
  type        = map(string)
  default     = {}
}
