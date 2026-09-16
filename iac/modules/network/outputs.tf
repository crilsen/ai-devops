output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.principal.id
}

output "vpc_cidr_block" {
  description = "Bloco CIDR da VPC criada"
  value       = aws_vpc.principal.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas, uma por AZ"
  value       = [for subnet in aws_subnet.publica : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas, uma por AZ"
  value       = [for subnet in aws_subnet.privada : subnet.id]
}
