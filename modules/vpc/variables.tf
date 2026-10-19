variable "name" {
  description = "Name prefix for every resource in the VPC."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}$", var.name))
    error_message = "name must be 2-41 characters: lowercase letters, digits and hyphens."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR for the VPC. Each subnet gets a /20 carved from it, so use a /16."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && endswith(var.cidr_block, "/16")
    error_message = "cidr_block must be a valid /16 IPv4 CIDR."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways so private subnets can reach the internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ. Cheaper; loses AZ redundancy."
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "If set, subnets get the kubernetes.io/cluster/<name> tag used by EKS load balancer discovery."
  type        = string
  default     = null
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs (all traffic) to CloudWatch Logs."
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "CloudWatch retention for flow logs, in days."
  type        = number
  default     = 30
}

variable "flow_logs_kms_key_arn" {
  description = "Optional KMS key ARN to encrypt the flow log group. Uses CloudWatch's default encryption when null."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
