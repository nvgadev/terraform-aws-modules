locals {
  port = 5432
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.identifier}-subnets" })
}

resource "aws_security_group" "this" {
  name        = "${var.identifier}-db"
  description = "PostgreSQL access for ${var.identifier}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.identifier}-db" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_security_groups" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "PostgreSQL from allowed security group"
  ip_protocol                  = "tcp"
  from_port                    = local.port
  to_port                      = local.port
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "from_cidrs" {
  count = length(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "PostgreSQL from allowed CIDR"
  ip_protocol       = "tcp"
  from_port         = local.port
  to_port           = local.port
  cidr_ipv4         = var.allowed_cidr_blocks[count.index]
}

data "aws_iam_policy_document" "monitoring_assume" {
  count = var.monitoring_interval > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name_prefix        = "${substr(var.identifier, 0, 24)}-rds-mon-"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_157:Multi-AZ is a variable; the demo runs single-AZ to halve cost.
  #checkov:skip=CKV_AWS_293:Deletion protection is a variable; demo environments are destroyed nightly.
  #checkov:skip=CKV_AWS_118:Enhanced Monitoring is a variable (monitoring_interval); off by default for cost.
  #checkov:skip=CKV_AWS_353:Performance Insights is a variable; off by default because small classes may not support it.
  #checkov:skip=CKV2_AWS_60:Copying tags is enabled; final snapshots are skipped only for throwaway environments.
  #checkov:skip=CKV2_AWS_30:Statement logging (log_statement) is noisy and costly for a demo; attach a parameter group to enable it.
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name                       = var.db_name
  username                      = var.master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  port                   = local.port
  publicly_accessible    = false
  multi_az               = var.multi_az

  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null

  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${var.identifier}-final"

  tags = merge(var.tags, { Name = var.identifier })
}
