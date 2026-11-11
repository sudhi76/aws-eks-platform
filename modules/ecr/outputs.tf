output "repository_urls" {
  description = "Repository URLs by name, for docker push and image references."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}
