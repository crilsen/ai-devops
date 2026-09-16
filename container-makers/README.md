# Boilerplate: Aplicacao Web + Agente de IA em Python

Estrutura inicial para projetos web com agentes de IA, pensada para ser desenvolvida com Claude Code, Codex e outras ferramentas de agente.

- **FastAPI** (async) como backend
- **Jinja2** para a interface web server-side (dark theme)
- **LangChain** como framework de agentes
- **PostgreSQL** + SQLAlchemy async para persistencia
- **Alembic** para migrations
- **pytest** para testes
- **AGENTS.md** + **CLAUDE.md** com as instrucoes para os agentes de IA

## Inicio rapido

Pre-requisitos: [uv](https://docs.astral.sh/uv/getting-started/installation/) e `make`. Docker so e necessario para o banco.

```bash
npx degit fabricioveronez/boilerplates/boilerplate-python-web-agent meu-agente
cd meu-agente

make init name=meu_agente   # renomeia o package, cria o .env e instala as dependencias
make dev                    # abra http://localhost:8000
```

O `npx degit` baixa so esta pasta do repositorio [fabricioveronez/boilerplates](https://github.com/fabricioveronez/boilerplates). Sem Node, clone o repositorio e copie a pasta `boilerplate-python-web-agent`.

Voce vera a pagina **Hello World**. Tambem estao disponiveis:

- `http://localhost:8000/api/hello` — `{"message": "Hello World"}`
- `http://localhost:8000/api/health` — health check
- `http://localhost:8000/docs` — documentacao interativa da API

O `name` e opcional: `make init` sem ele mantem o package como `my_agent_app`.

## Proximos passos

1. **Descreva o projeto** na secao "Sobre o projeto" do `AGENTS.md`.
2. **Configure o LLM** — preencha `ANTHROPIC_API_KEY` (e, se quiser, `LLM_MODEL`) no `.env`. O `AGENTS.md` define como os agentes devem ser criados em `agents/`.
3. **Suba o banco** quando precisar de persistencia:

   ```bash
   make setup-full                       # PostgreSQL + pgAdmin e migrations
   make revision m="cria tabela x"       # apos criar um modelo em models/
   make migrate
   ```

4. **Escreva os requisitos** em `docs/prds/` e as decisoes tecnicas em `docs/adrs/` antes de pedir a implementacao ao agente.

## Comandos

Rode `make` para ver todos os alvos.

| Comando | O que faz |
|---------|-----------|
| `make init [name=meu_agente]` | Inicializa o projeto |
| `make dev` | Sobe o app com reload |
| `make test` | Roda os testes |
| `make db-up` / `make db-down` | Sobe/derruba PostgreSQL + pgAdmin |
| `make migrate` | Aplica as migrations |
| `make revision m="..."` | Gera migration por autogenerate |
| `make setup-full` | Sobe o banco e aplica as migrations |

## Estrutura

```
.
├── AGENTS.md              # Instrucoes para agentes de IA (fonte unica)
├── CLAUDE.md              # Importa o AGENTS.md para o Claude Code
├── Makefile               # Inicializacao e comandos do dia a dia
├── docker-compose.yml     # PostgreSQL + pgAdmin
├── alembic.ini
├── migrations/            # Alembic (async)
├── docs/
│   ├── prds/              # Requisitos de produto
│   └── adrs/              # Decisoes de arquitetura
├── src/my_agent_app/
│   ├── main.py            # FastAPI + lifespan
│   ├── config.py          # Variaveis de ambiente
│   ├── database.py        # Base SQLAlchemy + get_session
│   ├── api/router.py      # /api/health, /api/hello
│   ├── web/router.py      # Pagina inicial + paginas de erro
│   ├── templates/         # base.html, home.html, error.html
│   ├── services/          # (vazio) Regras de negocio
│   ├── models/            # (vazio) Modelos SQLAlchemy
│   └── agents/            # (vazio) Agentes LangChain
└── tests/                 # pytest
```

## Stack

| Tecnologia | Uso |
|------------|-----|
| FastAPI + Uvicorn | Backend async |
| Jinja2 | Interface web server-side |
| LangChain | Framework de agentes de IA |
| SQLAlchemy 2.0 + asyncpg | ORM async com PostgreSQL |
| Alembic | Migrations |
| pytest | Testes |
| Docker Compose | Banco de dados local (PostgreSQL + pgAdmin) |
| uv + hatchling | Gerenciador de pacotes + build |
