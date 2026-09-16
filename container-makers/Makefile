# Nome do package Python, derivado do diretorio em src/ (continua valido apos `make init name=...`)
APP := $(patsubst src/%/__init__.py,%,$(firstword $(wildcard src/*/__init__.py)))
APP_SLUG := $(subst _,-,$(APP))
APP_TITLE := My Agent App

HOST ?= 0.0.0.0
PORT ?= 8000

.DEFAULT_GOAL := help
.PHONY: help init check-deps rename env install dev test db-up db-down migrate revision setup-full

help: ## Lista os comandos disponiveis
	@echo "Uso: make <alvo>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Inicio rapido: make init && make dev  ->  http://localhost:$(PORT)"

init: check-deps ## Inicializa o projeto (opcional: name=meu_agente renomeia o package)
ifdef name
	@$(MAKE) --no-print-directory rename name=$(name)
endif
	@$(MAKE) --no-print-directory env
	@$(MAKE) --no-print-directory install
	@echo ""
	@echo "Projeto pronto! Proximos passos:"
	@echo "  make dev        -> abra http://localhost:$(PORT) e veja o Hello World"
	@echo "  make test       -> roda os testes"
	@echo "  make setup-full -> sobe o PostgreSQL e aplica as migrations (quando usar banco)"

check-deps:
	@command -v uv >/dev/null 2>&1 || { echo "Erro: uv nao encontrado. Instale: https://docs.astral.sh/uv/getting-started/installation/"; exit 1; }
	@command -v docker >/dev/null 2>&1 || echo "Aviso: docker nao encontrado. Ele so e necessario para o banco (make db-up)."

rename: ## Renomeia o package: make rename name=meu_agente
	@test -n "$(name)" || { echo "Erro: informe o nome. Ex: make rename name=meu_agente"; exit 1; }
	@echo "$(name)" | grep -Eq '^[a-z][a-z0-9_]*$$' || { echo "Erro: '$(name)' deve ser snake_case (letras minusculas, numeros e _)."; exit 1; }
	@if [ "$(name)" = "$(APP)" ]; then echo "Package ja se chama $(APP), nada a renomear."; exit 0; fi; \
	new_slug=$$(echo "$(name)" | tr '_' '-'); \
	new_title=$$(echo "$(name)" | tr '_' ' ' | awk '{for (i = 1; i <= NF; i++) $$i = toupper(substr($$i, 1, 1)) substr($$i, 2)} 1'); \
	echo "Renomeando $(APP) -> $(name)"; \
	mv "src/$(APP)" "src/$(name)"; \
	grep -rlI --exclude-dir=.venv --exclude-dir=.git --exclude-dir=__pycache__ --exclude-dir=.pytest_cache \
		--exclude=uv.lock --exclude=.env -e "$(APP)" -e "$(APP_SLUG)" -e "$(APP_TITLE)" . | \
	while read -r file; do \
		sed -i.bak -e "s/$(APP)/$(name)/g" -e "s/$(APP_SLUG)/$$new_slug/g" -e "s/$(APP_TITLE)/$$new_title/g" "$$file" && rm -f "$$file.bak"; \
	done; \
	echo "Package renomeado para $(name) ($$new_title)."

env: ## Cria o .env a partir do .env.example (se nao existir)
	@if [ -f .env ]; then echo ".env ja existe, mantido."; else cp .env.example .env && echo ".env criado a partir do .env.example."; fi

install: ## Instala as dependencias (uv sync)
	uv sync

dev: ## Sobe a aplicacao com reload em http://localhost:8000
	uv run uvicorn $(APP).main:app --host $(HOST) --port $(PORT) --reload

test: ## Roda os testes
	uv run pytest

db-up: ## Sobe PostgreSQL + pgAdmin (docker compose)
	docker compose up -d

db-down: ## Derruba os containers do banco
	docker compose down

migrate: ## Aplica as migrations (alembic upgrade head)
	uv run alembic upgrade head

revision: ## Gera migration a partir dos modelos: make revision m="descricao"
	@test -n "$(m)" || { echo "Erro: informe a descricao. Ex: make revision m=\"cria tabela x\""; exit 1; }
	uv run alembic revision --autogenerate -m "$(m)"

setup-full: db-up migrate ## Sobe o banco e aplica as migrations
