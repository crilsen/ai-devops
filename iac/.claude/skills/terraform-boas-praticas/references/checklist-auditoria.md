# Checklist de auditoria

Percorra item a item contra o projeto real. Para cada item, reporte: conforme / divergente + por que importa + ajuste sugerido. Não aplique correções estruturais sozinho — só formatação (`terraform fmt`) é segura para corrigir direto.

| # | Item | Como checar | Por que importa |
|---|---|---|---|
| 1 | Versão do Terraform travada | `versions.tf` de cada ambiente tem `required_version = "= x.y.z"` (não `>=`/`~>`) | Constraint aberta quebra reprodutibilidade — um `init` futuro pode puxar versão diferente sem aviso |
| 2 | Versão de cada provider travada | `required_providers` com `version = "= x.y.z"` para todo provider usado | Mesmo motivo do item 1, por provider |
| 3 | Nenhum módulo de comunidade | Buscar por `source = "registry.terraform.io/..."` ou URLs de git de terceiros em qualquer `module` block | Módulo de terceiro tira o time do controle sobre o que roda em produção |
| 4 | Ambientes em pastas, não workspace | Existe `environments/{dev,homologacao,producao}/`; `terraform workspace list` não tem workspaces além de `default` sendo usados propositalmente | Workspace ativo errado é um erro fácil de cometer com consequência em produção |
| 5 | Backend parcial | `backend.tf` sem valores concretos; valores reais em `backend-<ambiente>.hcl` | Backend hardcoded amarra o projeto a uma conta específica, quebra reuso |
| 6 | State remoto, nunca local | Nenhum backend `local` (ou ausência de bloco `backend`) | State local não tem lock, não é compartilhável pelo time, risco de perda |
| 7 | Naming `snake_case` | Labels de recurso, variáveis, outputs em `snake_case`, sem redundância com o tipo do recurso | Consistência entre projetos e módulos |
| 8 | Tags padrão presentes | Recursos taggable têm ao menos `environment`, `project`, `managed_by` | Rastreabilidade mínima de qualquer recurso na cloud |
| 9 | Módulo autocontido e documentado | Cada módulo em `modules/` tem `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`; sem valor hardcoded dentro | Contrato claro é o que viabiliza reuso do módulo em outro projeto |
| 10 | `fmt`/`validate` limpos | `terraform fmt -check -recursive` e `terraform validate` (por ambiente) sem erros | Sinal básico de higiene; corrigir formatação é seguro fazer direto |
