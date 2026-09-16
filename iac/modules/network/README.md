# Módulo `network`

## Propósito

Provisiona uma VPC dedicada para um ambiente (dev ou homologação), com subnets públicas e privadas em múltiplas zonas de disponibilidade, Internet Gateway e um NAT Gateway por AZ — ver [ADR 001](../../docs/adrs/001-isolamento-rede-vpc-dedicada.md).

As subnets recebem as tags `kubernetes.io/cluster/<nome>` e `kubernetes.io/role/elb` / `kubernetes.io/role/internal-elb`, exigidas pelo *legacy in-tree cloud provider* da AWS para criar o Classic Load Balancer de um `Service type: LoadBalancer` (ver [ADR 004](../../docs/adrs/004-exposicao-service-loadbalancer-nativo.md)).

## Inputs

| Nome | Tipo | Descrição | Obrigatório |
|---|---|---|---|
| `vpc_cidr` | `string` | Bloco CIDR da VPC | Sim |
| `az_count` | `number` | Quantidade de AZs (mínimo 2) | Não (default `2`) |
| `public_subnet_cidrs` | `list(string)` | CIDRs das subnets públicas, um por AZ | Sim |
| `private_subnet_cidrs` | `list(string)` | CIDRs das subnets privadas, um por AZ | Sim |
| `cluster_name` | `string` | Nome do cluster EKS, usado só para tagging | Sim |
| `tags` | `map(string)` | Tags padrão do projeto | Não (default `{}`) |

## Outputs

| Nome | Descrição |
|---|---|
| `vpc_id` | ID da VPC criada |
| `vpc_cidr_block` | Bloco CIDR da VPC criada |
| `public_subnet_ids` | IDs das subnets públicas |
| `private_subnet_ids` | IDs das subnets privadas |

## Exemplo de uso

```hcl
module "network" {
  source = "../../modules/network"

  vpc_cidr              = "10.0.0.0/16"
  az_count              = 2
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  cluster_name          = "devops-com-ia-dev"
  tags                  = local.tags
}
```
