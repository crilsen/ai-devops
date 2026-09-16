---
adr_number: "006"
status: aceito
created: 2026-09-15
supersedes: ""
superseded_by: ""
---

# ADR 006: Autenticação ao cluster via EKS Access Entries (API mode)

## Contexto

Historicamente, o mapeamento entre identidades IAM e permissões RBAC do Kubernetes em EKS era feito editando o ConfigMap `aws-auth`, o que exige `kubectl` ou o provider `kubernetes` do Terraform. Como o projeto não usa Helm nem quer dependências adicionais de tooling (ADR 003), era preciso decidir como fazer esse mapeamento sem introduzir o provider `kubernetes`.

## Alternativas Consideradas

- **ConfigMap `aws-auth`** — caminho legado; editável via provider `kubernetes` do Terraform ou `kubectl`, o que introduziria uma dependência que o projeto está evitando.
- **EKS Access Entries (`authentication_mode = API`)** — API nativa da AWS para mapear identidades IAM a permissões no cluster, gerenciável inteiramente via `aws_eks_access_entry` e `aws_eks_access_policy_association` do provider `aws`, sem precisar do provider `kubernetes` *(Verificado — Terraform AWS provider docs / itnext.io, 2026-09-15)*.

## Decisão

O cluster usa `authentication_mode = API`, com o acesso gerenciado via `aws_eks_access_entry` / `aws_eks_access_policy_association`. Não há ConfigMap `aws-auth` nem provider `kubernetes` no Terraform deste projeto.

## Consequências

- **Positivas:** todo o mapeamento de acesso ao cluster fica dentro do mesmo provider `aws` já usado no restante do projeto, sem dependência adicional de tooling.
- **Negativas:** a mudança de `authentication_mode` é unidirecional (`CONFIG_MAP` → `API_AND_CONFIG_MAP` → `API`, sem caminho de volta) — reverter para o modelo `aws-auth` depois de adotar `API` não é uma operação trivial.
- **Neutras / trade-offs aceitos:** qualquer necessidade futura de gerenciar recursos Kubernetes diretamente via Terraform (fora do escopo de acesso) ainda exigiria reabrir a decisão de não usar o provider `kubernetes`.
