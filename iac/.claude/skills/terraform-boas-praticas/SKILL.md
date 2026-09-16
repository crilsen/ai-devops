---
name: terraform-boas-praticas
description: Aplica e audita a estrutura padrão de projetos Terraform da equipe — environments/ separados por ambiente (dev/homologacao/producao, nunca terraform workspace), módulos próprios em modules/ (nunca módulos de comunidade), versões de Terraform e de cada provider travadas na mais recente disponível no momento da criação, naming em snake_case, tagging padrão e backend de state parcial sem valores hardcoded. Detecta sozinha se deve criar um projeto Terraform do zero (scaffold), adicionar um módulo novo a um projeto existente, ou auditar um projeto Terraform já existente contra esse padrão. Use sempre que o usuário quiser "criar um projeto Terraform", "iniciar infraestrutura como código", "criar/adicionar um módulo Terraform", "revisar", "auditar" ou "padronizar" um projeto Terraform, estruturar pastas de ambiente, ou mencionar Terraform, HCL, provider, backend de state, .tfstate — mesmo sem dizer "boas práticas" explicitamente. Agnóstica de cloud provider: a mesma estrutura vale para AWS, Azure, GCP ou qualquer outro provider; os recursos dentro dos módulos continuam explícitos por provider.
---

# Terraform — Boas Práticas

Padroniza como projetos Terraform da equipe nascem e evoluem, e garante que fiquem reprodutíveis, modulares e reaproveitáveis entre projetos — sem depender de nenhuma cloud específica para fazer sentido.

## Regra inegociável: nunca alterar infraestrutura sozinha

`terraform apply` e `terraform destroy` mudam recursos reais de forma difícil (ou impossível) de reverter. Por isso, **esta skill nunca executa `apply` ou `destroy` por conta própria** — mesmo que pareça o próximo passo óbvio do fluxo. Só rode um desses dois comandos quando o usuário pedir explicitamente, e só o comando pedido — não encadeie um `apply` depois de um `plan` que o usuário não pediu.

`terraform fmt`, `terraform validate`, `terraform plan` e `terraform init` são seguros (não alteram infraestrutura, só leem ou preparam) e podem ser usados livremente durante scaffold e auditoria.

## Detectar o modo

Olhe o estado do diretório de trabalho (ou do diretório que o usuário apontar) antes de perguntar ao usuário o que ele quer:

| Estado observado | Modo | O que fazer |
|---|---|---|
| Diretório vazio ou sem nenhum arquivo `.tf` | **Scaffold** | Criar um projeto novo do zero, ver seção abaixo |
| Já existe `modules/` e/ou `environments/`, e o pedido é para acrescentar algo novo (um recurso, uma funcionalidade) | **Novo módulo** | Adicionar um módulo a um projeto existente, ver seção abaixo |
| Já existe código Terraform e o pedido é revisar, auditar, ou o usuário pergunta se está no padrão | **Auditoria** | Conferir o projeto contra `references/checklist-auditoria.md` |

Se o estado não deixar claro qual modo aplicar, pergunte — não adivinhe silenciosamente.

## Modo Scaffold — criar projeto novo

1. **Confirmar com o usuário**: nome/propósito do projeto, cloud provider(s) que vai usar, e se os três ambientes (dev, homologação, produção) são realmente necessários desde já ou se algum entra depois.
2. **Descobrir a versão mais recente do Terraform e de cada provider envolvido.** Isso é um fato externo que muda com frequência — nunca confie na memória do modelo para isso. Use o Terraform já instalado localmente (`terraform version`), consulte a documentação/registry do provider via Context7 ou busca na web, e registre a versão exata encontrada.
3. **Gerar o esqueleto de diretórios** rodando `scripts/scaffold.sh <raiz-do-projeto>`. Isso cria `modules/`, `environments/{dev,homologacao,producao}/` e os arquivos-base de cada ambiente (veja a estrutura completa em `references/estrutura-projeto.md`).
4. **Travar as versões descobertas no passo 2** editando o `versions.tf` de cada ambiente: `required_version = "= <versão do terraform>"` e, em `required_providers`, `version = "= <versão do provider>"`. Nunca deixe uma constraint aberta (`>=`, `~>`) — o objetivo é reprodutibilidade; atualizar depois é um ato deliberado.
5. **Preencher o `backend.tf`** de cada ambiente com o tipo de backend do provider escolhido (mantendo os valores fora do código — ver `references/state-backend.md`).
6. **Gerar `CONVENTIONS.md`** na raiz do projeto a partir de `assets/CONVENTIONS.md.template`, preenchendo os placeholders. Esse arquivo é o que deixa o padrão visível mesmo numa sessão futura sem esta skill carregada.
7. **Validar o esqueleto**: rodar `terraform fmt -recursive` e, em cada ambiente, `terraform validate` (após um `terraform init` sem backend real, ou com placeholders — não é preciso configurar o backend de verdade só para validar sintaxe).
8. Ao criar o primeiro módulo real dentro de `modules/`, siga `references/guidelines-modulos.md` e use `scripts/novo-modulo.sh` (mesmo fluxo do modo "Novo módulo" abaixo).

## Modo Novo módulo — adicionar a um projeto existente

Terraform cresce por módulo ao longo da vida do projeto, não só na criação. Quando o pedido é "adicionar X à infraestrutura":

1. Rode `scripts/novo-modulo.sh <raiz-do-projeto> <nome-do-modulo>` para criar o esqueleto (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`).
2. Siga o contrato descrito em `references/guidelines-modulos.md` — especialmente: nada hardcoded, inputs/outputs documentados, e **nunca puxar um módulo pronto do Terraform Registry ou de outra fonte de terceiros**. Se existir um módulo de comunidade que resolveria o problema, use-o como inspiração de desenho, mas implemente a versão própria dentro de `modules/`.
3. Componha o módulo novo dentro do(s) `environments/<ambiente>/main.tf` correspondente(s), com `source = "../../modules/<nome-do-modulo>"`.
4. Confira naming e tagging contra `references/naming-e-tagging.md`.
5. Rode `terraform fmt` e `terraform validate` no ambiente afetado.

## Modo Auditoria — revisar projeto existente

1. Percorra `references/checklist-auditoria.md` item a item contra o projeto real.
2. Rode `terraform fmt -check -recursive` e `terraform validate` em cada ambiente — corrija problemas de formatação diretamente (baixo risco), mas **não mova arquivos, renomeie diretórios nem reestruture o projeto sem confirmar antes com o usuário** — isso pode ter efeitos que só quem conhece o histórico do projeto percebe.
3. Reporte os achados de forma objetiva: o que está de acordo, o que diverge do padrão e por quê isso importa, e uma sugestão concreta de ajuste para cada divergência.

## Referências

| Arquivo | Quando ler |
|---|---|
| `references/estrutura-projeto.md` | Para saber exatamente que arquivos e pastas compõem o padrão (scaffold ou para comparar num audit) |
| `references/guidelines-modulos.md` | Antes de criar ou revisar qualquer módulo |
| `references/naming-e-tagging.md` | Ao nomear recursos/variáveis ou aplicar tags |
| `references/state-backend.md` | Ao configurar ou revisar o backend de state |
| `references/checklist-auditoria.md` | No modo Auditoria |
