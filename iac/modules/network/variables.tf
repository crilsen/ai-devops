variable "vpc_cidr" {
  description = "Bloco CIDR da VPC deste ambiente"
  type        = string
}

variable "az_count" {
  description = "Quantidade de zonas de disponibilidade a usar (mínimo 2)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "az_count deve ser no mínimo 2 (isolamento de rede exige múltiplas AZs)."
  }
}

variable "public_subnet_cidrs" {
  description = "Blocos CIDR das subnets públicas, um por AZ (tamanho deve bater com az_count)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Blocos CIDR das subnets privadas, um por AZ (tamanho deve bater com az_count)"
  type        = list(string)
}

variable "cluster_name" {
  description = "Nome do cluster EKS que vai usar esta rede, usado apenas para as tags kubernetes.io/cluster/* exigidas pelo Service type LoadBalancer"
  type        = string
}

variable "tags" {
  description = "Tags padrão do projeto, mescladas com as tags específicas de cada recurso"
  type        = map(string)
  default     = {}
}
