# Root module do ambiente "homologacao".
# Compõe módulos de ../../modules/<nome> — não declarar recursos de cloud diretamente aqui.

locals {
  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }

  cluster_name = "${var.project_name}-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
  tags                 = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name            = local.cluster_name
  kubernetes_version      = var.kubernetes_version
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids
  endpoint_private_access = var.endpoint_private_access
  admin_principal_arns    = var.admin_principal_arns
  tags                    = local.tags
}

module "node_group" {
  source = "../../modules/node-group"

  cluster_name   = module.eks.cluster_name
  subnet_ids     = module.network.private_subnet_ids
  instance_types = var.node_instance_types
  desired_size   = var.node_desired_size
  min_size       = var.node_min_size
  max_size       = var.node_max_size
  tags           = local.tags
}
