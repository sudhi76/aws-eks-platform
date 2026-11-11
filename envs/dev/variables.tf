variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the EKS control plane."
  type        = string
  default     = "1.35"
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the Kubernetes API, normally just your own IP as x.x.x.x/32."
  type        = list(string)
}

variable "admin_principal_arns" {
  description = "IAM roles or users that get cluster-admin. Include the role you run Terraform and kubectl with."
  type        = list(string)
}
