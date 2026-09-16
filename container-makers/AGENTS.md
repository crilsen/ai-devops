# AGENTS.md

Instrucoes para agentes de IA (Claude Code, Codex, Cursor e outros) que trabalham neste repositorio.

## Sobre o projeto

<!-- TODO: Descreva o proposito da aplicacao e do agente de IA aqui -->
Aplicacao web em Python com agente de IA: FastAPI (async) + Jinja2 na interface, LangChain para os agentes e PostgreSQL para persistencia.

## Inicio rapido

```bash
make init   # verifica o uv, cria o .env e instala as dependencias
make dev    # http://localhost:8000 -> pagina "Hello World"
```

A aplicacao sobe sem PostgreSQL e sem `ANTHROPIC_API_KEY`. Banco e LLM so sao necessarios quando o codigo passar a usa-los.

## Comandos

Use sempre o Makefile (rode `make` para ver todos os alvos):

| Comando | O que faz |
|---------|-----------|
| `make init name=meu_agente` | Inicializa o projeto; `name` e opcional e renomeia o package |
| `make dev` | Sobe o app com reload em `http://localhost:8000` |
| `make test` | Roda os testes (`uv run pytest`) |
| `make db-up` / `make db-down` | Sobe/derruba PostgreSQL + pgAdmin via docker compose |
| `make migrate` | Aplica as migrations (`alembic upgrade head`) |
| `make revision m="descricao"` | Gera migration por autogenerate a partir dos modelos |
| `make setup-full` | `db-up` + `migrate` |

Dependencias sao gerenciadas com `uv`: adicione com `uv add <pacote>` (ou `uv add --dev <pacote>`), nunca com `pip install`.

## Arquitetura

Codigo em `src/my_agent_app/`, empacotado via hatchling (`pyproject.toml`).

```
src/my_agent_app/
├── main.py         # FastAPI + lifespan (engine/sessionmaker em app.state) + registro de routers
├── config.py       # Leitura de variaveis de ambiente
├── database.py     # Base (DeclarativeBase) e dependency get_session
├── api/router.py   # Rotas JSON sob /api (/api/health, /api/hello)
├── web/router.py   # Paginas HTML (Jinja2) e handler de erro com error.html
├── templates/      # base.html (layout dark), home.html, error.html
├── services/       # Regras de negocio e orquestracao (a implementar)
├── models/         # Modelos SQLAlchemy (a implementar)
└── agents/         # Agentes LangChain (a implementar)
migrations/         # Alembic (async), le DATABASE_URL e Base.metadata
tests/              # pytest; fixture `client` em conftest.py
docs/               # prds/, adrs/ e trd.md
```

Fluxo entre camadas:

```
web/ e api/  ->  services/  ->  agents/ e models/
```

- Routers sao finos: validam a entrada, chamam um service e devolvem a resposta. Sem regra de negocio e sem chamada a LLM dentro de rota.
- `services/` orquestra: usa modelos para persistir e agentes para raciocinar.
- `agents/` nao conhece FastAPI nem `Request`; recebe dados e devolve resultados.

## Agentes de IA (`agents/`)

O diretorio comeca vazio. Ao criar o primeiro agente, siga esta convencao:

- **Modelo em um unico ponto** — crie `agents/llm.py` com uma funcao `get_chat_model()` que usa `init_chat_model` (`langchain.chat_models`) com o valor de `config.get_llm_model()` (formato `provider:modelo`, ex.: `anthropic:claude-sonnet-5`). Nenhum outro arquivo instancia modelo diretamente.
- **Um agente por arquivo** — `agents/<nome>_agent.py`, construido com `create_agent` (`langchain.agents`), passando modelo, tools e `system_prompt`. Exponha uma funcao async de alto nivel (ex.: `async def run_<nome>(...)`) que usa `ainvoke`.
- **Prompts** — system prompts longos ficam em `agents/prompts/<nome>.md` ou em constantes no topo do arquivo do agente.
- **Tools** — funcoes com `@tool` (`langchain.tools`) em `agents/tools/<dominio>.py`. Type hints e docstring viram o schema da tool: escreva-os com cuidado. Tools que tocam I/O devem ser async.
- **Chamadas externas** — nenhum teste unitario chama a API real do LLM; substitua o modelo por um fake/mock nos testes.
- **Consulte a documentacao atual** do LangChain antes de escrever codigo de agente; a API muda com frequencia.

## Convencoes

- **Async** em tudo que faz I/O (rotas, banco, chamadas a LLM e HTTP).
- **Banco** — obtenha sessoes com `Depends(get_session)`; nunca crie engine fora do `lifespan` de `main.py`.
- **Modelos** — cada modelo em `models/<nome>.py`, herdando de `Base`, e importado em `models/__init__.py` (senao o Alembic nao o enxerga).
- **Migrations** — toda mudanca de schema passa por `make revision m="..."` + `make migrate`. Revise a migration gerada antes de aplicar.
- **Interface web** — paginas estendem `base.html`; estilos genericos (`card`, `btn`, `empty-state`) ficam no `base.html`, estilos de pagina no bloco `extra_style`.
- **Configuracao** — variaveis de ambiente sao lidas em `config.py`; novas variaveis tambem entram no `.env.example` e na tabela abaixo.
- **Testes** — em `tests/test_<assunto>.py`, usando a fixture `client`. Todo endpoint novo ganha teste. Rode `make test` antes de concluir uma tarefa.
- **Idioma** — codigo (nomes de variaveis, funcoes, classes) em ingles; textos da interface, docs e nomes de testes em portugues.

## Variaveis de ambiente

| Variavel | Descricao | Padrao |
|----------|-----------|--------|
| `DATABASE_URL` | Connection string PostgreSQL async | `postgresql+asyncpg://app:app123@localhost:5432/my_agent_app` |
| `ANTHROPIC_API_KEY` | Chave de API da Anthropic | (obrigatoria so ao usar agentes) |
| `LLM_MODEL` | Modelo dos agentes, formato `provider:modelo` | `anthropic:claude-sonnet-5` |

## Infraestrutura

O Docker provisiona **apenas o banco**. A aplicacao roda localmente via `uv`.

| Servico | Porta | Credenciais |
|---------|-------|-------------|
| PostgreSQL 17 | 5432 | app / app123 / my_agent_app |
| pgAdmin | 5050 | admin@admin.com / admin123 |

## Documentacao do projeto

- `docs/prds/` — PRDs (requisitos de produto), um arquivo por feature: `NNN-nome.md`
- `docs/trd.md` — requisitos tecnicos e decisoes globais (criar quando necessario)
- `docs/adrs/` — registros de decisao de arquitetura: `NNN-titulo.md`

Leia o PRD e o TRD relacionados antes de implementar uma feature.
