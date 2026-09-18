# ai-devops

Repositório do projeto "DevOps com IA", construído ao vivo em aula. Reúne os
requisitos de produto (**PRDs**), a aplicação que implementa esses requisitos
(**container-makers**) e a infraestrutura como código (**iac**).

## O que é o projeto

O produto central é o **docker-maker**: um serviço web local que recebe a URL de
um repositório do GitHub e devolve os artefatos de conteinerização do projeto
(Dockerfile e docker compose) já validados, entregues numa branch nova do próprio
repositório, junto de um relatório em markdown que explica cada decisão.

O difícil não é escrever um Dockerfile, e sim **descobrir do que a aplicação
precisa para rodar**. Um erro nisso só aparece quando se tenta subir a aplicação.
Por isso o produto aposta em dois pilares:

1. **Mapeamento com evidência** — toda dependência precisa de evidência no
   repositório (driver/biblioteca, `.env.example`, compose existente, doc).
2. **Validação real** — os artefatos são construídos e executados de verdade no
   Docker local, com ciclo de correção, e o status final vem de uma validação
   independente do agente.

O escopo é dividido em dois PRDs por tecnologia:

- **PRD 001 — Docker**: gera e valida Dockerfile + compose, relatório e entrega
  via branch no GitHub.
- **PRD 002 — Kubernetes**: extensão que gera manifestos Kubernetes a partir do
  mesmo mapeamento do PRD 001 e os valida num cluster local (kind).

## Estrutura do repositório

```
.
├── docs-projeto/
│   └── prds/                 # PRDs (requisitos de produto)
│       ├── 001-conteinerizacao-docker.md
│       └── 002-extensao-kubernetes.md
├── container-makers/         # Implementação do docker-maker (aplicação Python)
├── iac/                      # Infraestrutura Terraform (EKS por ambiente)
└── slides/                   # Slides das aulas
```

## docs-projeto/prds — requisitos de produto

Os PRDs são a fonte de verdade do que deve ser construído. Cada PRD tem o mesmo
formato: contexto e problema, solução proposta (visão + decisões + fora do
escopo), funcionalidades em user stories (US) com regras e edge cases, fluxo de
negócio, critérios de aceite (observáveis), milestones, riscos, dependências e
registro de decisões.

- **`001-conteinerizacao-docker.md`** — PRD base. Define o serviço web local de
  um usuário só, entrega por push de branch (sem PR, e sempre, mesmo com a
  validação falhando), mapeamento de dependências com evidência, geração de
  artefatos, validação real em Docker com ciclo de correção, melhoria de
  artefatos existentes, observações do usuário, relatório na raiz e entrega no
  GitHub. Critérios **C01–C15**, 5 milestones.
- **`002-extensao-kubernetes.md`** — extensão (`depends_on: ["001"]`). Reaproveita
  o mapeamento de dependências do PRD 001 sem remapear, gera manifestos da
  aplicação e das dependências (separados, os das dependências marcados como de
  desenvolvimento) e valida num cluster local com kind. Critérios **K01–K10**,
  3 milestones.

Leia o PRD relacionado **antes** de implementar uma funcionalidade.

## container-makers — a aplicação do docker-maker

Implementação do produto descrito nos PRDs. Parte de um boilerplate de aplicação
web Python com agente de IA:

- **FastAPI** (async) como backend
- **Jinja2** para a interface web server-side (dark theme)
- **LangChain** como framework de agentes
- **PostgreSQL** + SQLAlchemy async para persistência
- **Alembic** para migrations
- **pytest** para testes
- **uv + hatchling** para dependências e build

### Início rápido

Pré-requisitos: [uv](https://docs.astral.sh/uv/getting-started/installation/) e
`make`. Docker só é necessário para o banco.

```bash
cd container-makers
make init name=meu_agente   # renomeia o package, cria o .env e instala as dependências
make dev                    # abra http://localhost:8000
```

A aplicação sobe sem PostgreSQL e sem `ANTHROPIC_API_KEY`; banco e LLM só são
necessários quando o código passar a usá-los. Veja `make` para todos os alvos e
`container-makers/README.md` para detalhes.

### Arquitetura

Código em `src/my_agent_app/`, com separação de camadas:

```
web/ e api/  →  services/  →  agents/ e models/
```

- Routers são finos: validam a entrada, chamam um service e devolvem a resposta.
- `services/` orquestra as regras de negócio e a persistência.
- `agents/` são agentes LangChain; não conhecem FastAPI.

Convenções completas (async, banco, modelos, migrations, testes, idioma) estão em
**`container-makers/AGENTS.md`** — leia antes de contribuir.

## iac — infraestrutura Terraform

Provisiona um cluster **Amazon EKS por ambiente** (`dev` e `homologacao`), cada
um com sua VPC dedicada, para hospedar a aplicação web exposta via
`Service type: LoadBalancer` nativo do Kubernetes.

```
modules/          # network (VPC/subnets/NAT), eks (cluster + IAM + access entries),
                  # node-group (Managed Node Group EC2 + IAM)
environments/     # dev/ e homologacao/ (um root module por ambiente)
```

Uso, decisões de arquitetura (TRD + ADRs 001–006) e convenções de código estão em
**`iac/README.md`** e **`iac/CONVENTIONS.md`**. Pontos de atenção:

- O state é **local** (desvio deliberado do padrão da equipe; `.tfstate` nunca
  deve ser commitado).
- `terraform apply` e `terraform destroy` **nunca são executados
  automaticamente** — apenas quando solicitados explicitamente.

## slides

Slides das aulas em PDF (`slides/aula-01.pdf`).
