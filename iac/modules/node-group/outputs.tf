output "node_group_arn" {
  description = "ARN do Managed Node Group"
  value       = aws_eks_node_group.principal.arn
}

output "node_group_status" {
  description = "Status atual do Managed Node Group"
  value       = aws_eks_node_group.principal.status
}
