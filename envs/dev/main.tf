locals {
  environment = "dev"
  name        = "platform-${local.environment}"
}

module "network" {
  source = "../../modules/network"

  name         = local.name
  cluster_name = local.name

  # One NAT gateway is enough for a dev environment and saves about $65 a month.
  single_nat_gateway = true
}

module "eks" {
  source = "../../modules/eks"

  name               = local.name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = module.network.private_subnet_ids

  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  admin_principal_arns         = var.admin_principal_arns
}

module "ecr" {
  source = "../../modules/ecr"

  repositories = ["linkpulse/api"]

  # dev is torn down after every session, images included.
  force_delete = true
}
