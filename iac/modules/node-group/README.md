# Módulo `node-group`

## Propósito

Provisiona um Managed Node Group (EC2) para hospedar os pods da aplicação web ([ADR 002](../../docs/adrs/002-compute-managed-node-groups.md)).

**Decisão importante**: este módulo não cria nenhuma security group customizada nem `launch_template`. Sem `launch_template` explícito, o node group herda automaticamente a security group gerenciada pelo EKS, que o *legacy in-tree cloud provider* já sabe modificar dinamicamente para liberar o tráfego do Classic Load Balancer e dos health checks de um `Service type: LoadBalancer` ([ADR 004](../../docs/adrs/004-exposicao-service-loadbalancer-nativo.md)). Adicionar uma SG própria autoritativa aqui reverteria essa liberação a cada `apply` seguinte — não faça isso sem reabrir a decisão do ADR 004.

## Inputs

| Nome | Tipo | Descrição | Obrigatório |
|---|---|---|---|
| `cluster_name` | `string` | Nome do cluster EKS | Sim |
| `subnet_ids` | `list(string)` | Subnets (privadas) onde os nodes são lançados | Sim |
| `instance_types` | `list(string)` | Tipos de instância EC2 | Não (default `["t3.medium"]`) |
| `capacity_type` | `string` | `ON_DEMAND` ou `SPOT` | Não (default `"ON_DEMAND"`) |
| `ami_type` | `string` | Tipo de AMI | Não (default `"AL2023_x86_64_STANDARD"`) |
| `disk_size` | `number` | Tamanho do disco (GB) | Não (default `20`) |
| `desired_size` | `number` | Quantidade desejada de nodes | Sim |
| `min_size` | `number` | Quantidade mínima de nodes | Sim |
| `max_size` | `number` | Quantidade máxima de nodes | Sim |
| `tags` | `map(string)` | Tags padrão do projeto | Não (default `{}`) |

## Outputs

| Nome | Descrição |
|---|---|
| `node_group_arn` | ARN do Managed Node Group |
| `node_group_status` | Status atual do Managed Node Group |

## Exemplo de uso

```hcl
module "node_group" {
  source = "../../modules/node-group"

  cluster_name   = module.eks.cluster_name
  subnet_ids     = module.network.private_subnet_ids
  instance_types = ["t3.medium"]
  desired_size   = 2
  min_size       = 1
  max_size       = 3
  tags           = local.tags
}
```
