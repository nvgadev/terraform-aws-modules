mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/iq-test-rds-mon"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  identifier = "iq-test-db"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
}

run "secure_defaults" {
  command = plan

  variables {
    allowed_security_group_ids = ["sg-0123456789abcdef0"]
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted && !aws_db_instance.this.publicly_accessible
    error_message = "Database must be encrypted and private."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password
    error_message = "Master password must be managed by RDS in Secrets Manager."
  }

  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled
    error_message = "IAM database authentication should be on."
  }

  assert {
    condition     = aws_db_instance.this.instance_class == "db.t4g.micro" && aws_db_instance.this.storage_type == "gp3"
    error_message = "Defaults should be a burstable instance on gp3."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.from_security_groups) == 1 && length(aws_vpc_security_group_ingress_rule.from_cidrs) == 0
    error_message = "Expected exactly one ingress rule from the allowed security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.from_security_groups[0].from_port == 5432
    error_message = "Ingress must be on 5432 only."
  }

  assert {
    condition     = length(aws_iam_role.monitoring) == 0
    error_message = "No Enhanced Monitoring role unless monitoring_interval > 0."
  }
}

run "long_lived_settings" {
  command = plan

  variables {
    multi_az            = true
    deletion_protection = true
    skip_final_snapshot = false
    monitoring_interval = 60
  }

  assert {
    condition     = aws_db_instance.this.final_snapshot_identifier == "iq-test-db-final"
    error_message = "A final snapshot name is needed when snapshots are kept."
  }

  assert {
    condition     = length(aws_iam_role.monitoring) == 1 && aws_db_instance.this.monitoring_interval == 60
    error_message = "Enhanced Monitoring role should exist when monitoring is on."
  }
}

run "rejects_single_subnet" {
  command = plan

  variables {
    subnet_ids = ["subnet-0aaaaaaaaaaaaaaaa"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_bad_identifier" {
  command = plan

  variables {
    identifier = "IQ_DB"
  }

  expect_failures = [var.identifier]
}
