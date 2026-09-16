#!/usr/bin/env bash
set -euo pipefail

# Cria o esqueleto padrão de um projeto Terraform (skill terraform-boas-praticas).
# As versões do Terraform/provider e o tipo de backend ficam como TODO —
# preencha-os depois de descobrir a versão mais recente real (ver SKILL.md).
#
# Uso: scaffold.sh <diretorio-raiz-do-projeto>

ROOT="${1:?uso: scaffold.sh <diretorio-raiz-do-projeto>}"
ENVS=(dev homologacao producao)

mkdir -p "$ROOT/modules"
mkdir -p "$ROOT/environments"
: > "$ROOT/modules/.gitkeep"

cat > "$ROOT/.gitignore" <<'EOF'
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
!*.tfvars.example
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc
EOF

for env in "${ENVS[@]}"; do
  dir="$ROOT/environments/$env"
  mkdir -p "$dir"

  cat > "$dir/versions.tf" <<EOF
terraform {
  # TODO: travar na versão mais recente do Terraform disponível no momento do scaffold (ex: "= 1.9.5")
  required_version = "= 0.0.0"

  required_providers {
    # TODO: adicionar o(s) provider(s) reais, travados na versão mais recente (ex:
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "= 5.60.0"
    # }
  }
}
EOF

  cat > "$dir/backend.tf" <<EOF
terraform {
  # Backend parcial — sem valores concretos. Os valores deste ambiente ($env)
  # vêm de backend-$env.hcl:
  #   terraform init -backend-config=backend-$env.hcl
  # TODO: escolher o tipo de backend do provider usado (ex: "s3", "azurerm", "gcs")
  backend "TODO" {}
}
EOF

  cat > "$dir/backend-$env.hcl" <<EOF
# Valores concretos do backend de state para o ambiente "$env".
# TODO: preencher (bucket/account/subscription/path/etc.). Nunca hardcode isso em backend.tf.
EOF

  cat > "$dir/main.tf" <<EOF
# Root module do ambiente "$env".
# Compõe módulos de ../../modules/<nome> — não declarar recursos de cloud diretamente aqui.
EOF

  cat > "$dir/variables.tf" <<EOF
variable "environment" {
  description = "Nome do ambiente"
  type        = string
  default     = "$env"
}

variable "project_name" {
  description = "Nome do projeto, usado em tags"
  type        = string
}
EOF

  : > "$dir/outputs.tf"

  cat > "$dir/terraform.tfvars.example" <<EOF
# Copie para terraform.tfvars e preencha com valores não sensíveis do ambiente "$env".
# project_name = "..."
EOF
done

echo "Esqueleto criado em $ROOT (modules/, environments/{${ENVS[*]}})"
