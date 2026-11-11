# Runs offline: the AWS provider is mocked, so these check the module's own logic.

mock_provider "aws" {
  # The provider validates ARNs, so the mocked ones need a real shape.
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:ap-south-1:123456789012:log-group:test" }
  }

  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/test" }
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
    }
  }

  override_data {
    target = data.aws_iam_policy_document.flow_logs_assume
    values = { json = "{}" }
  }

  override_data {
    target = data.aws_iam_policy_document.flow_logs[0]
    values = { json = "{}" }
  }
}

variables {
  name         = "test"
  cluster_name = "test"
}

run "subnets_do_not_overlap" {
  command = plan

  assert {
    condition     = aws_subnet.private[*].cidr_block == ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
    error_message = "Private subnets should be the first three /19s of the VPC."
  }

  assert {
    condition     = aws_subnet.public[*].cidr_block == ["10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"]
    error_message = "Public subnets should be /24s starting at 10.0.192.0."
  }

  assert {
    condition     = aws_subnet.private[*].availability_zone == ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
    error_message = "Each private subnet should be in a different AZ."
  }
}

run "single_nat_gateway_by_default" {
  command = apply

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Expected one NAT gateway when single_nat_gateway is true."
  }

  assert {
    condition     = length(distinct(aws_route.private_nat[*].nat_gateway_id)) == 1
    error_message = "Every private route table should use the single NAT gateway."
  }
}

run "nat_gateway_per_az" {
  command = apply

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Expected one NAT gateway per AZ."
  }

  assert {
    condition     = length(distinct(aws_route.private_nat[*].nat_gateway_id)) == 3
    error_message = "Each private route table should use its own AZ's NAT gateway."
  }
}

run "flow_logs_can_be_disabled" {
  command = plan

  variables {
    flow_log_retention_days = 0
  }

  assert {
    condition     = length(aws_flow_log.this) == 0
    error_message = "No flow log should be created when retention is 0."
  }
}

run "rejects_non_16_cidr" {
  command = plan

  variables {
    cidr = "10.0.0.0/20"
  }

  expect_failures = [var.cidr]
}

run "rejects_single_az" {
  command = plan

  variables {
    az_count = 1
  }

  expect_failures = [var.az_count]
}
