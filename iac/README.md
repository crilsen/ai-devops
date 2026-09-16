# iac — infraestrutura Terraform

Provisiona um cluster Amazon EKS por ambiente (`dev` e `homologacao`), cada um com sua própria VPC dedicada, para hospedar uma aplicação web exposta via `Service type: LoadBalancer` nativo do Kubernetes.

As decisões de arquitetura por trás deste projeto (isolamento de rede, compute via Managed Node Groups, ausência de Helm/GitOps/Vault, exposição de workloads, endpoint público do EKS e autenticação via Access Entries) estão documentadas em [`docs/trd.md`](docs/trd.md) e nos ADRs em [`docs/adrs/`](docs/adrs/). As convenções de código/estrutura Terraform aplicadas estão em [`CONVENTIONS.md`](CONVENTIONS.md).

## Estrutura

```
modules/
├── network/     # VPC, subnets públicas/privadas, IGW, NAT Gateway por AZ
├── eks/         # cluster EKS, IAM do cluster, access entries
└── node-group/  # Managed Node Group EC2 + IAM dos nodes
environments/
├── dev/
└── homologacao/
```

## Uso

Em `environments/<ambiente>/`:

```bash
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com os valores do ambiente (região, CIDRs, admin_principal_arns, etc.)

terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

O state deste projeto é **local** (ver `CONVENTIONS.md`), então `terraform init` não precisa de nenhum backend remoto configurado.

`terraform apply` e `terraform destroy` só devem ser executados manualmente, quando você decidir provisionar ou destruir recursos reais na AWS.

Depois do `apply`, configure o `kubectl`:

```bash
aws eks update-kubeconfig --name <cluster_name> --region <aws_region>
```
