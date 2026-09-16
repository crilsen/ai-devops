variable "cluster_name" {
  description = "Nome do cluster EKS ao qual este node group pertence"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets (privadas) onde os nodes são lançados"
  type        = list(string)
}

variable "instance_types" {
  description = "Tipos de instância EC2 usados pelos nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Tipo de capacidade do node group (ON_DEMAND ou SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "ami_type" {
  description = "Tipo de AMI usada pelos nodes"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "disk_size" {
  description = "Tamanho do disco (GB) de cada node"
  type        = number
  default     = 20
}

variable "desired_size" {
  description = "Quantidade desejada de nodes"
  type        = number
}

variable "min_size" {
  description = "Quantidade mínima de nodes"
  type        = number
}

variable "max_size" {
  description = "Quantidade máxima de nodes"
  type        = number
}

variable "tags" {
  description = "Tags padrão do projeto, mescladas com as tags específicas de cada recurso"
  type        = map(string)
  default     = {}
}
