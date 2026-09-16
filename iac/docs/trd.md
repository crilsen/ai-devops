# TRD — Technical Requirements Document

> Documento técnico global do projeto. Criado e atualizado via skill `escrever-trd`.
> Carregado automaticamente por `preparar-execucao` e `implementar-task` como contexto global.
> Granularidade baixa: cobre o que é global e estável. Regras finas ficam em ADRs.

---

## Stack

| Dimensão | Valor |
|---|---|
| Linguagem principal | HCL (Terraform) |
| Runtime / plataforma | Terraform 1.16.2 *(Verificado — `terraform version` local, 2026-09-15)* |
| Provider principal | `hashicorp/aws` 6.64.0 *(Verificado — Terraform Registry, 2026-09-15)* |
| Banco de dados | Não aplicável — projeto não provisiona banco de dados |
| Ferramentas de build | `terraform fmt`, `terraform validate`, `terraform plan` |
| Gerenciador de pacotes | Terraform Registry apenas para providers oficiais; módulos são sempre próprios, nunca de terceiros *(padrão `terraform-boas-praticas`)* |

---

## Arquitetura

### Padrão arquitetural

Infraestrutura como código modular: módulos próprios em `modules/`, ambientes isolados por diretório em `environments/` (nunca `terraform workspace`), cada ambiente com state remoto próprio *(padrão da equipe — skill `terraform-boas-praticas`)*.

Plataforma de destino: Amazon EKS, com uma VPC exclusiva por ambiente (uma para desenvolvimento, outra para homologação — nenhuma compartilhada), mínimo 2 zonas de disponibilidade em cada, compute via Managed Node Groups, sem Helm/Ingress Controller — exposição de aplicação via `Service type: LoadBalancer` nativo. Ver ADRs 001 a 006 para o raciocínio de cada decisão.

### Estrutura de pastas dominante

```
devops-com-ia/
├── CONVENTIONS.md
├── README.md
├── modules/
│   ├── network/       # VPC, subnets públicas/privadas, IGW, NAT Gateway por AZ
│   ├── eks/            # cluster EKS, endpoint público, access entries
│   └── node-group/     # Managed Node Group EC2
└── environments/
    ├── dev/
    └── homologacao/
```

*(`environments/producao/` fica de fora por agora — adiamento explícito do escopo, entra no mesmo layout quando for endereçado)*

### Módulos / camadas principais

| Módulo | Responsabilidade |
|---|---|
| `network` | VPC dedicada, subnets públicas/privadas em ≥2 AZs, Internet Gateway, um NAT Gateway por AZ |
| `eks` | Cluster EKS com endpoint público, `authentication_mode = API`, access entries |
| `node-group` | Managed Node Group EC2 para os pods da aplicação web |

*(Inferido — divisão de módulos deduzida das decisões de arquitetura; ajustar se a implementação pedir outro corte)*

---

## Requisitos Não-Funcionais

| Dimensão | Requisito |
|---|---|
| Performance | Não definido |
| Disponibilidade / SLA | Alta disponibilidade via múltiplas AZs (mínimo 2): VPC, subnets, NAT Gateway (um por AZ) e node group distribuídos entre elas. RPO/RTO não definidos |
| Escalabilidade | Não definido |
| Segurança | Endpoint do API server do EKS público, sem restrição de IP; sem Vault; sem uso de Secrets do Kubernetes; sem dado sensível/regulado no momento |
| Observabilidade | Nenhuma nesta fase |

---

## Dependências Externas

| Serviço / Sistema | Tipo | Constraint relevante | Dono |
|---|---|---|---|
| Amazon EKS | Serviço gerenciado AWS | Suporta até Kubernetes 1.37, versão mais recente disponível *(Verificado — AWS What's New, 2026-09-15)*; endpoint público habilitado | interno — infra |
| AWS NAT Gateway | Serviço gerenciado AWS | Um por AZ; cobrança por hora + tráfego processado | interno — infra |
| Legacy in-tree AWS Cloud Provider (`Service type: LoadBalancer`) | Componente nativo do Kubernetes na AWS | Provisiona Classic Load Balancer; em modo de manutenção — só recebe correção crítica, sem evolução *(Verificado — WebSearch, 2026-09-15)* | interno — infra |

---

## Padrões

### Testes

| Item | Valor |
|---|---|
| Framework | Terraform test nativo (`.tftest.hcl`) |
| Comando completo | `terraform test` por módulo/ambiente |
| Cobertura mínima | Não definida |
| Estratégia | `*_unit_test.tftest.hcl` (modo `plan`, sem criar recursos) + `*_integration_test.tftest.hcl` (modo `apply`, recursos reais) |

### Estilo de código

- **Linter/Formatter:** `terraform fmt`
- **Convenções de nomenclatura:** `snake_case` para recursos, variáveis, outputs e locals; o label do recurso não repete o tipo (ex.: `aws_eks_cluster.principal`, não `aws_eks_cluster.eks_cluster`)

### Error handling

Não aplicável no sentido tradicional — falhas de `plan`/`apply` são reportadas pelo próprio Terraform. Validação prévia via `terraform fmt -check` e `terraform validate` antes de qualquer `apply`.

### Logging

Não aplicável — observabilidade da infraestrutura provisionada está fora de escopo nesta fase (decisão explícita, ver ADR 003).

### Autenticação / autorização

Acesso ao state via backend S3 remoto (bloco parcial, sem valor hardcoded) com lock e IAM. Tags padrão (`environment`, `project = devops-com-ia`, `managed_by = terraform`) em todo recurso. Acesso ao cluster Kubernetes via `authentication_mode = API` do EKS (`aws_eks_access_entry` / `aws_eks_access_policy_association`) — sem `aws-auth` ConfigMap, sem provider `kubernetes` no Terraform (ver ADR 006).

---

## Decisões Globais (ADRs)

| # | Título | Data | Status | Link |
|---|--------|------|--------|------|
| 001 | Isolamento de rede por ambiente via VPC dedicada | 2026-09-15 | aceito | [docs/adrs/001-isolamento-rede-vpc-dedicada.md](adrs/001-isolamento-rede-vpc-dedicada.md) |
| 002 | Compute via Managed Node Groups, não Fargate | 2026-09-15 | aceito | [docs/adrs/002-compute-managed-node-groups.md](adrs/002-compute-managed-node-groups.md) |
| 003 | Sem Helm, GitOps ou Vault nesta fase | 2026-09-15 | aceito | [docs/adrs/003-sem-helm-gitops-vault.md](adrs/003-sem-helm-gitops-vault.md) |
| 004 | Exposição de workloads via Service type LoadBalancer nativo | 2026-09-15 | aceito | [docs/adrs/004-exposicao-service-loadbalancer-nativo.md](adrs/004-exposicao-service-loadbalancer-nativo.md) |
| 005 | Endpoint do API server do EKS público, sem restrição de IP | 2026-09-15 | aceito | [docs/adrs/005-endpoint-api-server-publico.md](adrs/005-endpoint-api-server-publico.md) |
| 006 | Autenticação ao cluster via EKS Access Entries (API mode) | 2026-09-15 | aceito | [docs/adrs/006-autenticacao-eks-access-entries.md](adrs/006-autenticacao-eks-access-entries.md) |
