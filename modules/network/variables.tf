variable "name" {
  description = "Name prefix for every resource in the VPC."
  type        = string
}

variable "cidr" {
  description = "IPv4 CIDR block of the VPC. Must be a /16: subnets are carved out of it as /19s (private) and /24s (public)."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr, 0)) && endswith(var.cidr, "/16")
    error_message = "cidr must be a valid /16 IPv4 block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 (EKS needs at least two AZs)."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all private subnets. Cheaper, but egress fails if that AZ goes down; set false for one NAT gateway per AZ."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster that will use the subnets. Used for the subnet discovery tags of the load balancer controller and Karpenter."
  type        = string
}

variable "flow_log_retention_days" {
  description = "Days to keep VPC flow logs in CloudWatch. Set 0 to disable flow logs."
  type        = number
  default     = 14
}
