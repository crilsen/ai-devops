# Convenções deste projeto Terraform

Este projeto segue o padrão `terraform-boas-praticas`. Resumo das regras aplicadas aqui — se você é um agente (ou pessoa) trabalhando neste repo sem essa skill carregada, siga isto:

## Estrutura

- `modules/`: módulos próprios, reutilizáveis entre projetos. **Nunca** módulos de comunidade/registry de terceiros.
- `environments/{dev,homologacao}/`: um root module por ambiente, cada um compõe módulos de `modules/`. Separação por pasta — **nunca** `terraform workspace`. `producao/` fica de fora por agora (adiamento explícito, ver `docs/trd.md` e [ADR 001](docs/adrs/001-isolamento-rede-vpc-dedicada.md)).

## Versionamento

- Terraform `= 1.16.2` e provider `hashicorp/aws` `= 6.64.0` — travados na versão mais recente disponível no momento da criação deste projeto (15/09/2026). Atualizar versão é sempre uma ação deliberada, nunca automática.

## Módulos

- Cada módulo é autocontido: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
- Sem valores hardcoded — tudo parametrizado via `variables.tf`.
- Responsabilidade única por módulo: `network` (VPC/subnets/NAT), `eks` (cluster + IAM + access entries), `node-group` (Managed Node Group + IAM).

## Naming e tagging

- `snake_case` para recursos, variáveis e outputs.
- Tags mínimas em todo recurso taggable: `environment`, `project = "devops-com-ia"`, `managed_by = "terraform"`.

## State — desvio deliberado do padrão da equipe

O padrão `terraform-boas-praticas` manda usar sempre um backend remoto (S3 com lock), nunca local. **Neste projeto o state é local** (nenhum bloco `backend` declarado em `versions.tf`/`main.tf` de cada ambiente) — escolha explícita do dono do projeto para este ambiente de estudo, não um esquecimento. Consequências aceitas: sem lock entre execuções concorrentes, sem durabilidade além do disco local, `.tfstate` nunca deve ser commitado (já coberto pelo `.gitignore`). Se este projeto evoluir para uso em equipe ou produção, reabrir esta decisão e migrar para backend S3 conforme `state-backend.md` da skill.

## Execução

- `terraform fmt`, `validate`, `plan` e `init` podem ser rodados livremente.
- `terraform apply` e `terraform destroy` **nunca são executados automaticamente** — apenas quando solicitados explicitamente pelo usuário, comando a comando.

## Decisões de arquitetura

Toda decisão de infraestrutura (rede, compute, exposição de workloads, acesso ao cluster) está documentada em `docs/trd.md` e `docs/adrs/001` a `006`. Não reabra essas decisões sem um novo ADR.

---
Gerado pela skill `terraform-boas-praticas`, com a seção de State ajustada para este projeto.
