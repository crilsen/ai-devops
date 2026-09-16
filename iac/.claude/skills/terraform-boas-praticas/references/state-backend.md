# State e backend

## Backend parcial, nunca hardcoded

O bloco `terraform { backend "..." {} }` em `backend.tf` declara **só o tipo** de backend (`s3`, `azurerm`, `gcs`, `remote`, etc.), sem nenhum valor concreto:

```hcl
terraform {
  backend "s3" {}
}
```

Os valores reais (bucket, conta, assinatura, caminho, região, tabela de lock, etc.) ficam em `backend-<ambiente>.hcl`, dentro da pasta do próprio ambiente, e são injetados na hora do `init`:

```
terraform init -backend-config=backend-dev.hcl
```

### Por que separar assim

- O mesmo `backend.tf` funciona em qualquer conta/projeto/organização — só muda o `.hcl` passado. Isso é o que torna a estrutura reaproveitável entre projetos, não só entre ambientes do mesmo projeto.
- Evita o erro clássico de copiar um projeto para outra conta e esquecer de trocar um valor de backend hardcoded no meio do `.tf` — com backend parcial, o valor sempre vem de fora, então não tem onde esconder um valor errado dentro do código versionado.

## Nunca local state

State nunca fica em disco local (backend `local`, que é o default se nenhum backend for declarado). Sempre um backend remoto, com lock, apropriado ao provider do projeto.

## O que versionar

- `backend.tf` (o bloco parcial) — sempre versionado, é só estrutura.
- `backend-<ambiente>.hcl` — versionado **somente se não contiver segredo** (nomes de bucket/conta geralmente não são segredo). Se algum valor for sensível, mova para uma variável de ambiente ou secret manager e mantenha o `.hcl` fora do controle de versão — avalie caso a caso ao auditar um projeto.
- `.tfstate` — nunca versionado. Vive só no backend remoto.
