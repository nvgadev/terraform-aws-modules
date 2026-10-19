variable "identifier" {
  description = "RDS instance identifier; also the prefix for the subnet group and security group."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.identifier)) && !endswith(var.identifier, "-") && !strcontains(var.identifier, "--")
    error_message = "identifier must start with a letter, use lowercase letters, digits and single hyphens, and be at most 63 characters."
  }
}

variable "vpc_id" {
  description = "VPC for the database security group."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs (at least two AZs) for the DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs in different AZs."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on the PostgreSQL port (for example the EKS node or pod security group)."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect on the PostgreSQL port. Keep to private ranges."
  type        = list(string)
  default     = []
}

variable "engine_version" {
  description = "PostgreSQL major version (AWS picks the default minor) or a full version string."
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "Instance class. Burstable classes keep the demo cheap."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB. Set equal to allocated_storage to disable autoscaling."
  type        = number
  default     = 50
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master user name. Its password is generated and kept in Secrets Manager by RDS."
  type        = string
  default     = "app_admin"
}

variable "multi_az" {
  description = "Run a standby in a second AZ."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Days to keep automated backups (0 disables them)."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Block deletion of the instance. Turn on for anything long-lived."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. True suits throwaway demo environments."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key for storage, Performance Insights and the master secret. AWS managed keys are used when null."
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights. Off by default: not every small instance class supports it."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0 disables it; 60 is the cheapest when on)."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
