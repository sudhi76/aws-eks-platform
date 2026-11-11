variable "name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the control plane, for example \"1.35\"."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the control plane network interfaces and the nodes. At least two AZs."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint. Keep this to your own IP; set an empty list to make the endpoint private only."
  type        = list(string)
}

variable "admin_principal_arns" {
  description = "IAM roles or users that get cluster-admin through EKS access entries."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Days to keep control plane logs in CloudWatch."
  type        = number
  default     = 14
}

variable "node_group" {
  description = "Settings for the managed node group. Defaults to Graviton (arm64) spot instances to keep cost down."
  type = object({
    instance_types = optional(list(string), ["t4g.medium", "m7g.medium"])
    ami_type       = optional(string, "AL2023_ARM_64_STANDARD")
    capacity_type  = optional(string, "SPOT")
    min_size       = optional(number, 1)
    desired_size   = optional(number, 2)
    max_size       = optional(number, 3)
    disk_size_gb   = optional(number, 20)
  })
  default = {}

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group.capacity_type)
    error_message = "node_group.capacity_type must be ON_DEMAND or SPOT."
  }

  validation {
    condition     = var.node_group.min_size <= var.node_group.desired_size && var.node_group.desired_size <= var.node_group.max_size
    error_message = "node_group sizes must satisfy min_size <= desired_size <= max_size."
  }
}
