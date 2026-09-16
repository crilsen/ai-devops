output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do API server do cluster"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID da VPC deste ambiente"
  value       = module.network.vpc_id
}
