variable "environment" {
  description = "Nome do ambiente"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nome do projeto, usado em tags"
  type        = string
  default     = "devops-com-ia"
}

variable "aws_region" {
  description = "Região AWS onde a infraestrutura deste ambiente é provisionada"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC deste ambiente"
  type        = string
}

variable "az_count" {
  description = "Quantidade de zonas de disponibilidade a usar (mínimo 2)"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "Blocos CIDR das subnets públicas, um por AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Blocos CIDR das subnets privadas, um por AZ"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes do cluster EKS"
  type        = string
  default     = "1.37"
}

variable "endpoint_private_access" {
  description = "Se o endpoint do API server também deve ser acessível de dentro da VPC"
  type        = bool
  default     = true
}

variable "admin_principal_arns" {
  description = "ARNs IAM adicionais que recebem acesso de admin ao cluster via EKS Access Entry"
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Tipos de instância EC2 usados pelos nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Quantidade desejada de nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Quantidade mínima de nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Quantidade máxima de nodes"
  type        = number
  default     = 3
}
