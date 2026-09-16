# Módulo `eks`

## Propósito

Provisiona um cluster Amazon EKS com endpoint público sem restrição de IP ([ADR 005](../../docs/adrs/005-endpoint-api-server-publico.md)) e autenticação via EKS Access Entries, sem ConfigMap `aws-auth` e sem provider `kubernetes` ([ADR 006](../../docs/adrs/006-autenticacao-eks-access-entries.md)).

Quem roda o `apply` que cria o cluster recebe acesso de admin automaticamente (`bootstrap_cluster_creator_admin_permissions = true`); `admin_principal_arns` concede acesso de admin a identidades IAM adicionais.

## Inputs

| Nome | Tipo | Descrição | Obrigatório |
|---|---|---|---|
| `cluster_name` | `string` | Nome do cluster | Sim |
| `kubernetes_version` | `string` | Versão do Kubernetes | Não (default `"1.37"`) |
| `public_subnet_ids` | `list(string)` | Subnets públicas para o control plane | Sim |
| `private_subnet_ids` | `list(string)` | Subnets privadas para o control plane | Sim |
| `endpoint_private_access` | `bool` | Habilita acesso ao endpoint de dentro da VPC | Não (default `true`) |
| `admin_principal_arns` | `list(string)` | ARNs IAM com acesso de admin adicional | Não (default `[]`) |
| `tags` | `map(string)` | Tags padrão do projeto | Não (default `{}`) |

## Outputs

| Nome | Descrição |
|---|---|
| `cluster_name` | Nome do cluster |
| `cluster_arn` | ARN do cluster |
| `cluster_endpoint` | Endpoint do API server |
| `cluster_certificate_authority_data` | CA do cluster, para o kubeconfig |
| `cluster_security_group_id` | Security group gerenciada pelo EKS |

## Exemplo de uso

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name         = "devops-com-ia-dev"
  kubernetes_version   = "1.37"
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids
  admin_principal_arns = ["arn:aws:iam::123456789012:user/exemplo"]
  tags                 = local.tags
}
```
