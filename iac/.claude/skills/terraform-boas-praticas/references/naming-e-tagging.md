# Naming e tagging

Convenções que independem de cloud provider — valem igual para um projeto AWS, Azure, GCP ou qualquer outro.

## Naming

- **`snake_case`** para nomes de recursos (o label lógico do Terraform, não o nome do recurso na cloud), variáveis, outputs e locals. Exemplo: `resource "aws_s3_bucket" "access_logs" { ... }`, não `"accessLogs"` nem `"AccessLogs"`.
- O label do recurso não repete o tipo do recurso. `resource "aws_s3_bucket" "bucket"` não diz nada que `aws_s3_bucket` já não dissesse — prefira `resource "aws_s3_bucket" "access_logs"`.
- Nome de arquivo segue sempre `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` — não dividir em arquivos extras (`network.tf`, `iam.tf`, ...) dentro de um módulo pequeno; se o módulo cresceu a ponto de precisar disso, provavelmente deveria virar mais de um módulo (ver responsabilidade única em `guidelines-modulos.md`).

## Tagging

Todo recurso que aceita tags/labels recebe, no mínimo:

| Chave | Valor | Propósito |
|---|---|---|
| `environment` | `dev` / `homologacao` / `producao` | Identifica o ambiente a partir do próprio recurso na cloud |
| `project` | nome do projeto | Rastreabilidade entre recursos e o repositório/projeto que os gerencia |
| `managed_by` | `terraform` | Sinaliza que o recurso não deve ser editado manualmente no console da cloud |

Times podem estender com `owner`/`team` quando fizer sentido, mas essas três são o mínimo em qualquer projeto.

### Como aplicar sem repetir em todo recurso

No `main.tf` de cada ambiente, declare um `local.tags` com os valores padrão e passe-o para os módulos via a variável `tags` (ver `guidelines-modulos.md`):

```hcl
locals {
  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

module "exemplo" {
  source = "../../modules/exemplo"
  tags   = local.tags
  # ...
}
```

Dentro do módulo, mescle `var.tags` com quaisquer tags específicas do módulo usando `merge()`, nunca substitua um pelo outro.
