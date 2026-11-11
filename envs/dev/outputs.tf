output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "kubeconfig_command" {
  description = "Command that adds the cluster to your kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_urls" {
  description = "ECR repository URLs by name."
  value       = module.ecr.repository_urls
}

output "nat_public_ips" {
  description = "Public IPs of the cluster's outbound traffic."
  value       = module.network.nat_public_ips
}
