variable "cluster_name" {
  description = "EKS cluster name; also the prefix for its IAM roles and node group."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,37}$", var.cluster_name))
    error_message = "cluster_name must start with a letter and use at most 38 letters, digits or hyphens."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version, for example \"1.34\". Pick one in standard support: aws eks describe-cluster-versions --query 'clusterVersions[?versionStatus==`STANDARD_SUPPORT`].clusterVersion'."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.kubernetes_version))
    error_message = "kubernetes_version must look like 1.34."
  }
}

variable "support_type" {
  description = "STANDARD makes AWS auto-upgrade at end of standard support instead of billing for extended support."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.support_type)
    error_message = "support_type must be STANDARD or EXTENDED."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs (at least two AZs) for the control plane ENIs and nodes."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs in different AZs."
  }
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API publicly (restricted to public_access_cidrs). The private endpoint is always on."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint, for example your home IP as x.x.x.x/32."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.endpoint_public_access || (length(var.public_access_cidrs) > 0 && !contains(var.public_access_cidrs, "0.0.0.0/0"))
    error_message = "With a public endpoint, list at least one CIDR and do not use 0.0.0.0/0."
  }
}

variable "cluster_log_types" {
  description = "Control plane log types sent to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition     = alltrue([for t in var.cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)])
    error_message = "Valid log types: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cluster_log_retention_days" {
  description = "CloudWatch retention for control plane logs, in days."
  type        = number
  default     = 30
}

variable "create_kms_key" {
  description = "Create a KMS key for Kubernetes secrets encryption. Ignored when kms_key_arn is set."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN for secrets encryption."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn != null || var.create_kms_key
    error_message = "Secrets encryption is required: set kms_key_arn or keep create_kms_key = true."
  }
}

variable "admin_principal_arns" {
  description = "IAM role or user ARNs given cluster-admin through EKS access entries (for example your SSO role and the CI apply role)."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for the managed node group. Several types improve Spot availability."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_ami_type" {
  description = "EKS AMI type. Use AL2023_ARM_64_STANDARD for Graviton (t4g, m7g) instances."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_disk_size_gb" {
  description = "Root volume size for each node, in GiB."
  type        = number
  default     = 30
}

variable "node_min_size" {
  description = "Minimum nodes."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired nodes at creation. Later changes by an autoscaler are ignored."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes."
  type        = number
  default     = 3

  validation {
    condition     = var.node_min_size <= var.node_desired_size && var.node_desired_size <= var.node_max_size
    error_message = "Node sizes must satisfy min <= desired <= max."
  }
}

variable "node_labels" {
  description = "Kubernetes labels for the nodes."
  type        = map(string)
  default     = {}
}

variable "node_metadata_hop_limit" {
  description = "IMDSv2 hop limit. 1 blocks pods from the node's instance credentials; 2 lets pods without Pod Identity read instance metadata."
  type        = number
  default     = 2

  validation {
    condition     = contains([1, 2], var.node_metadata_hop_limit)
    error_message = "node_metadata_hop_limit must be 1 or 2."
  }
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore so nodes can be reached with Session Manager instead of SSH."
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Install the EBS CSI driver add-on with a Pod Identity role."
  type        = bool
  default     = true
}

variable "addon_versions" {
  description = "Optional pinned add-on versions, keyed by add-on name. Unlisted add-ons use the default version for the cluster."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
