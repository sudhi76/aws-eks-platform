variable "repositories" {
  description = "Names of the ECR repositories to create."
  type        = list(string)
}

variable "untagged_expiry_days" {
  description = "Delete untagged images after this many days."
  type        = number
  default     = 7
}

variable "max_tagged_images" {
  description = "Keep at most this many tagged images per repository; older ones are deleted."
  type        = number
  default     = 50
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repositories that still contain images. Only for throwaway environments."
  type        = bool
  default     = false
}
