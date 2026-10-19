mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1c", "us-east-1a", "us-east-1b"]
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:111122223333:log-group:/aws/vpc/iq-test/flow-logs"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/iq-test-flowlogs"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name = "iq-test"
  tags = { project = "insurequote" }
}

run "defaults_two_azs_single_nat" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public and 2 private subnets."
  }

  assert {
    condition     = join(",", local.azs) == "us-east-1a,us-east-1b"
    error_message = "AZs should be the first two in sorted order."
  }

  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.20.0.0/20" && aws_subnet.private[0].cidr_block == "10.20.128.0/20"
    error_message = "Subnet CIDRs are not carved as expected."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat) == 2
    error_message = "Expected one shared NAT gateway routed from both private subnets."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs."
  }

  assert {
    condition     = length(aws_flow_log.this) == 0
    error_message = "Flow logs must be off by default."
  }
}

run "nat_per_az_and_flow_logs" {
  command = plan

  variables {
    az_count           = 3
    single_nat_gateway = false
    enable_flow_logs   = true
    eks_cluster_name   = "iq-eks"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Expected one NAT gateway per AZ."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1 && aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Expected one flow log capturing all traffic."
  }

  assert {
    condition     = aws_subnet.private[0].tags["kubernetes.io/cluster/iq-eks"] == "shared"
    error_message = "Private subnets should carry the EKS cluster tag."
  }
}

run "no_nat" {
  command = plan

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0
    error_message = "No NAT gateways or NAT routes when disabled."
  }
}

run "rejects_bad_cidr" {
  command = plan

  variables {
    cidr_block = "10.0.0.0/24"
  }

  expect_failures = [var.cidr_block]
}
