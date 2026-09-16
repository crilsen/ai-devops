# Estrutura de projeto

Árvore canônica que todo projeto Terraform criado ou auditado por esta skill deve seguir:

```
projeto-raiz/
├── CONVENTIONS.md
├── README.md
├── .gitignore
├── modules/
│   └── <nome-do-modulo>/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── versions.tf
    │   ├── backend.tf
    │   ├── backend-dev.hcl
    │   └── terraform.tfvars.example
    ├── homologacao/
    │   └── (mesmo layout de dev/)
    └── producao/
        └── (mesmo layout de dev/)
```

## Por que essa forma

- **`modules/` separado de `environments/`** — módulos são a unidade reutilizável; ambientes são a unidade de composição e deploy. Misturar os dois impede reaproveitar o módulo em outro projeto sem arrastar decisões específicas de um ambiente.
- **Um diretório por ambiente, nunca `terraform workspace`** — cada ambiente tem seu próprio state, backend e ciclo de `plan`/`apply`, isolados de verdade. Workspace guarda múltiplos states sob a mesma configuração e depende de lembrar qual workspace está ativo antes de rodar qualquer comando — um erro fácil de cometer e caro de pagar em produção.
- **Nomes `dev` / `homologacao` / `producao`** — os três ambientes padrão da equipe. Se um projeto não precisar de algum deles agora, é aceitável omitir a pasta, mas o nome, quando existir, segue esse padrão.

## Papel de cada arquivo (dentro de `environments/<ambiente>/`)

| Arquivo | Papel |
|---|---|
| `main.tf` | Root module do ambiente. Só compõe módulos via blocos `module`, nunca declara recursos de cloud diretamente aqui. |
| `variables.tf` | Inputs do ambiente (ex: `environment`, region/location, tamanhos, contagens específicas deste ambiente). |
| `outputs.tf` | O que este ambiente expõe para fora (ex: para outro ambiente consumir, ou para CI/CD ler). |
| `versions.tf` | `required_version` do Terraform e `required_providers` — sempre travados com `=` na versão mais recente descoberta no momento da criação/último bump (ver `SKILL.md`, passo de scaffold). |
| `backend.tf` | Bloco de backend **parcial** — declara o tipo (`s3`, `azurerm`, `gcs`, etc.) sem nenhum valor. Ver `state-backend.md`. |
| `backend-<ambiente>.hcl` | Valores concretos do backend deste ambiente, passados via `terraform init -backend-config=backend-<ambiente>.hcl`. |
| `terraform.tfvars.example` | Documenta as variáveis esperadas deste ambiente, sem valores sensíveis. O `.tfvars` real (com valores reais) é gerado localmente e nunca commitado. |

## Papel de cada arquivo (dentro de `modules/<nome>/`)

Ver `guidelines-modulos.md` para o contrato completo de um módulo.

## Arquivos na raiz do projeto

- **`CONVENTIONS.md`** — gerado a partir de `assets/CONVENTIONS.md.template` no scaffold. Documenta o padrão aplicado neste projeto especificamente, para que fique visível mesmo sem esta skill carregada numa sessão futura.
- **`README.md`** — descrição do projeto em si (o que ele provisiona, não as convenções — isso é papel do `CONVENTIONS.md`).
- **`.gitignore`** — nunca versionar `.terraform/`, arquivos de state (`*.tfstate*`) ou `.tfvars` com valores reais.
