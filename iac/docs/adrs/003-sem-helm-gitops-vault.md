---
adr_number: "003"
status: aceito
created: 2026-09-15
supersedes: ""
superseded_by: ""
---

# ADR 003: Sem Helm, GitOps ou Vault nesta fase

## Contexto

O projeto está começando do zero, cobrindo apenas dev e homologação, sem estado externo e sem dado sensível/regulado. Antes de introduzir ferramental de plataforma (gerenciador de pacotes Kubernetes, operador de GitOps, cofre de segredos), era preciso decidir o quanto de automação/tooling faz sentido para esse estágio do projeto, dado que não há indicação de um time de plataforma dedicado operando o cluster.

## Alternativas Consideradas

- **Adotar Helm + GitOps (ArgoCD/Flux) + Vault desde já** — modelo mais próximo do que produção provavelmente vai exigir, mas adiciona superfície operacional (charts, sincronização de estado do GitOps, gestão de um cofre de segredos) sem uma necessidade concreta declarada neste estágio.
- **Modelo enxuto, sem essas ferramentas** — reduz drasticamente o que precisa ser mantido e entendido para operar dev/hml, à custa de reavaliar cada peça individualmente quando (e se) produção exigir.

## Decisão

Nenhuma das três ferramentas — Helm, GitOps e Vault — é usada nesta fase do projeto. Qualquer componente do cluster que dependeria de Helm (ex.: AWS Load Balancer Controller) fica de fora; ver ADR 004 para a consequência direta sobre exposição de workloads.

## Consequências

- **Positivas:** superfície operacional mínima para dev/hml; menos ferramenta para o time entender e manter; TRD e módulos Terraform ficam mais simples, sem provider `helm` nem `kubernetes` adicionais.
- **Negativas:** funcionalidades que dependeriam dessas ferramentas (Ingress com roteamento por host/path via AWS Load Balancer Controller, deploy declarativo via GitOps, segredos centralizados e versionados via Vault) não estão disponíveis nesta fase.
- **Neutras / trade-offs aceitos:** essa decisão é reavaliada por ambiente/fase, não é permanente — quando produção for endereçada, cada uma dessas ferramentas pode ser reconsiderada individualmente, com uma nova decisão que supersede esta.
