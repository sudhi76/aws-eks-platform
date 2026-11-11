output "state_bucket" {
  description = "S3 bucket for remote state. Put it in envs/<env>/backend.hcl."
  value       = aws_s3_bucket.state.bucket
}

output "github_plan_role_arn" {
  description = "Role for the plan job. Store it as the AWS_PLAN_ROLE_ARN repository variable."
  value       = aws_iam_role.github_plan.arn
}
