---
adr_number: "004"
status: aceito
created: 2026-09-15
supersedes: ""
superseded_by: ""
---

# ADR 004: Exposição de workloads via Service type LoadBalancer nativo

## Contexto

A aplicação web precisa de um caminho de entrada de tráfego externo. O padrão mais comum em EKS para isso é o AWS Load Balancer Controller (ALB Ingress), mas ele é distribuído e mantido via Helm — o que está descartado por decisão explícita (ADR 003). Era preciso decidir como o tráfego chega à aplicação sem esse controller.

## Alternativas Consideradas

- **AWS Load Balancer Controller via Helm** — padrão recomendado pela AWS, cria um Application Load Balancer com roteamento por host/path e IngressGroup; descartado por depender de Helm.
- **`Service` do Kubernetes tipo `LoadBalancer` nativo** — não depende de nenhum controller adicional; usa o *legacy in-tree cloud provider* da AWS, que cria um Classic Load Balancer (CLB) automaticamente para o Service.

## Decisão

A aplicação web é exposta via um `Service` Kubernetes do tipo `LoadBalancer`, sem Ingress e sem AWS Load Balancer Controller.

## Consequências

- **Positivas:** exposição funciona sem nenhuma dependência de Helm ou de um controller adicional a manter.
- **Negativas:** o *legacy in-tree cloud provider* da AWS está em modo de manutenção — recebe apenas correção crítica, sem evolução *(Verificado — WebSearch, 2026-09-15)*. O CLB resultante não tem roteamento por host/path nem IngressGroup; serve bem um único serviço exposto, mas não escala para múltiplos serviços com regras de roteamento distintas sem reabrir esta decisão.
- **Neutras / trade-offs aceitos:** se o projeto precisar futuramente de roteamento HTTP mais sofisticado (múltiplos serviços atrás do mesmo load balancer, path-based routing), esta decisão precisa ser revisitada — o que reabriria também a decisão de não usar Helm (ADR 003).
