variable "repositories" {
  description = "Repository names to create, for example [\"insurequote/quote-api\"]."
  type        = set(string)

  validation {
    condition     = length(var.repositories) > 0 && alltrue([for r in var.repositories : can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*$", r))])
    error_message = "Each repository name must be lowercase and may use '/', '.', '_' and '-' between alphanumeric parts."
  }
}

variable "image_tag_mutability" {
  description = "IMMUTABLE (recommended) stops a tag from being overwritten."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "scan_on_push" {
  description = "Run ECR basic vulnerability scanning when an image is pushed."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Customer managed KMS key for image encryption. When null, the AWS managed aws/ecr key is used."
  type        = string
  default     = null
}

variable "max_tagged_images" {
  description = "Keep this many most recent tagged images per repository; older ones expire."
  type        = number
  default     = 30

  validation {
    condition     = var.max_tagged_images >= 1
    error_message = "max_tagged_images must be at least 1."
  }
}

variable "untagged_expiry_days" {
  description = "Delete untagged images after this many days."
  type        = number
  default     = 7
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repositories that still contain images. Handy for throwaway demo environments."
  type        = bool
  default     = false
}

variable "pull_principal_arns" {
  description = "Extra IAM principal ARNs (for example other accounts) allowed to pull images. Same-account roles need only IAM permissions."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags added to every repository."
  type        = map(string)
  default     = {}
}
