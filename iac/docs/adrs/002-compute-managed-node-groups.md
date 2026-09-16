---
adr_number: "002"
status: aceito
created: 2026-09-15
supersedes: ""
superseded_by: ""
---

# ADR 002: Compute via Managed Node Groups, não Fargate

## Contexto

O cluster EKS precisa hospedar os pods de uma aplicação web. Não há decisão de observabilidade, GitOps ou Vault nesta fase (ver ADR 003), o que reduz a capacidade de detectar e diagnosticar problema de node degradado caso a operação de node fique a cargo do time. Era preciso decidir se o compute seria gerido diretamente (EC2 via Managed Node Groups) ou totalmente abstraído (Fargate).

## Alternativas Consideradas

- **AWS Fargate** — zero gestão de node/AMI, cobrança por pod, reduziria a superfície operacional a quase zero; porém não suporta DaemonSet nem `hostPath`/EBS diretamente, e tem cold start mais lento para pods novos.
- **Managed Node Groups (EC2)** — mais controle sobre o compute, suporta qualquer padrão de workload (incluindo DaemonSet, se necessário no futuro), custo mais previsível em escala; exige gestão de AMI/patch dos nodes.

## Decisão

O compute do cluster usa **Managed Node Groups (EC2)**. Fargate foi descartado explicitamente para este cenário.

## Consequências

- **Positivas:** compute com controle total, sem as limitações de workload do Fargate (DaemonSet, volumes, etc.), e custo mais previsível para uma carga de aplicação web contínua.
- **Negativas:** a gestão de AMI e patch dos nodes fica com o time — sem observabilidade dedicada (ADR 003), um node degradado pode passar despercebido até afetar a aplicação.
- **Neutras / trade-offs aceitos:** dimensionamento (tipo de instância, contagem mínima/máxima do node group) fica para a implementação, não é parte desta decisão.
