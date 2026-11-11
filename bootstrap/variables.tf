variable "region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "ap-south-1"
}

variable "github_repository" {
  description = "GitHub repository, as owner/name, whose pull requests may run terraform plan."
  type        = string
  default     = "sudhi76/aws-eks-platform"
}

variable "noncurrent_state_retention_days" {
  description = "Days to keep old versions of state files, for recovering from a bad apply."
  type        = number
  default     = 90
}
