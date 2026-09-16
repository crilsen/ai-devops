---
adr_number: "005"
status: aceito
created: 2026-09-15
supersedes: ""
superseded_by: ""
---

# ADR 005: Endpoint do API server do EKS público, sem restrição de IP

## Contexto

O EKS permite configurar o endpoint do API server como público, privado, ou público+privado com allowlist de CIDR. Essa escolha define quem consegue alcançar o plano de controle do cluster pela rede, o que é uma decisão de postura de segurança com efeito sobre todo o cluster.

## Alternativas Consideradas

- **Endpoint privado (ou público+privado com allowlist de IP)** — reduz a superfície de rede exposta; exige VPN, bastion ou execução de `kubectl` de dentro da VPC (ou de uma origem específica).
- **Endpoint público, sem restrição de IP** — qualquer host na internet alcança o API server; a autenticação IAM (ou, neste projeto, EKS Access Entries — ver ADR 006) continua sendo a barreira de acesso, mas a superfície de rede fica maior.

## Decisão

O endpoint do API server do EKS é **público, sem restrição de IP de origem**.

## Consequências

- **Positivas:** acesso ao `kubectl` simples, sem depender de VPN, bastion ou rede específica — qualquer desenvolvedor com credencial IAM válida consulta o cluster de onde estiver.
- **Negativas:** a superfície de rede do plano de controle fica exposta à internet; qualquer host pode tentar autenticar contra o API server, o que amplia a exposição a tentativas de acesso indevido e a scanners automatizados, mesmo que a autenticação IAM barre o acesso de fato.
- **Neutras / trade-offs aceitos:** essa decisão vale para dev/hml; ao endereçar produção, ela deve ser reavaliada explicitamente — não é assumido que o mesmo endpoint público valha para o ambiente produtivo.
