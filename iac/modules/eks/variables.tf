variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes do cluster EKS"
  type        = string
  default     = "1.37"
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas onde o cluster pode colocar ENIs do control plane"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas onde o cluster pode colocar ENIs do control plane"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Se o endpoint do API server também deve ser acessível de dentro da VPC (o acesso público já é fixo, sem restrição, conforme ADR 005)"
  type        = bool
  default     = true
}

variable "admin_principal_arns" {
  description = "ARNs IAM adicionais que recebem acesso de admin ao cluster via EKS Access Entry, além de quem cria o cluster (que já recebe acesso automático)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags padrão do projeto, mescladas com as tags específicas de cada recurso"
  type        = map(string)
  default     = {}
}
