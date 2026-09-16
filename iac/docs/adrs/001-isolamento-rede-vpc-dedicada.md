---
adr_number: "001"
status: aceito
created: 2026-09-15
supersedes: ""
superseded_by: ""
---

# ADR 001: Isolamento de rede por ambiente via VPC dedicada

## Contexto

O projeto EKS vai rodar dev e homologação numa única conta AWS. Sem um limite de isolamento de rede claro entre os dois ambientes, um erro de configuração (rota, security group, CIDR sobreposto) em um ambiente pode se propagar para o outro. Além disso, produção entrará depois na mesma conta, e o desenho de rede escolhido agora deveria já antecipar esse futuro sem exigir reforma estrutural.

## Alternativas Consideradas

- **VPC única compartilhada, segregando dev/hml por subnet ou namespace** — menos NAT Gateway e menos custo de rede, mas isolamento apenas lógico: um erro de rota ou de regra de security group pode vazar de um ambiente para o outro.
- **Uma VPC exclusiva por ambiente** (dev e homologação em VPCs separadas) — isolamento real de rede (CIDR, tabelas de rota, security groups totalmente separados), replica o padrão que produção também vai usar, mas dobra (e depois triplica) o número de recursos de rede e o custo de NAT Gateway.

## Decisão

Existem **VPCs distintas, uma por ambiente**: uma VPC exclusiva para desenvolvimento e outra VPC exclusiva para homologação — nenhuma delas é compartilhada entre os dois ambientes. Cada VPC tem no mínimo 2 zonas de disponibilidade. Quando produção for endereçada, ela recebe sua própria VPC seguindo o mesmo padrão.

## Consequências

- **Positivas:** isolamento real entre ambientes na mesma conta AWS; o módulo `network` é reaproveitado sem alteração quando produção for endereçada.
- **Negativas:** mais recursos de rede provisionados (uma VPC completa por ambiente), com custo de NAT Gateway e demais componentes multiplicado pelo número de ambientes.
- **Neutras / trade-offs aceitos:** não há peering nem compartilhamento de rede entre dev e hml por padrão; se algum fluxo futuro precisar de comunicação entre ambientes, isso exige uma decisão de rede adicional (peering ou Transit Gateway), fora do escopo desta decisão.
