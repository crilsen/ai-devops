output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.principal.name
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.principal.arn
}

output "cluster_endpoint" {
  description = "Endpoint do API server do cluster"
  value       = aws_eks_cluster.principal.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado da autoridade certificadora do cluster, para configurar o kubeconfig"
  value       = aws_eks_cluster.principal.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "ID da security group gerenciada pelo EKS, herdada automaticamente pelo Managed Node Group"
  value       = aws_eks_cluster.principal.vpc_config[0].cluster_security_group_id
}
