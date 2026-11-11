output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, one per AZ. Nodes run here."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per AZ. Internet-facing load balancers run here."
  value       = aws_subnet.public[*].id
}

output "nat_public_ips" {
  description = "Public IPs the cluster's outbound traffic comes from."
  value       = aws_eip.nat[*].public_ip
}
