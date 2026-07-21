# EKS Cluster Terraform Module

Creates an Amazon EKS cluster with:

- EKS control plane + CloudWatch control-plane logging
- IAM roles for the cluster and worker nodes (least-privilege managed policies)
- IAM OIDC provider for IRSA (IAM Roles for Service Accounts)
- One or more managed node groups (on-demand or spot, with labels/taints)
- Core add-ons (`vpc-cni`, `coredns`, `kube-proxy`) — extend via `enabled_cluster_addons`
- Cluster access entries (modern replacement for the `aws-auth` ConfigMap) for mapping additional IAM roles to Kubernetes RBAC groups

## Requirements

- Terraform >= 1.3.0
- AWS provider >= 5.0 (needed for `access_config` / `aws_eks_access_entry`)
- An existing VPC with subnets across at least 2 AZs (private subnets recommended for node groups; both public+private subnets recommended if you want internet-facing load balancers)

## Usage

```hcl
module "eks" {
  source = "git::https://your-repo.git//eks-module?ref=v1.0.0"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.29"
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4
    }
    workers = {
      instance_types = ["m5.xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 3
      min_size       = 1
      max_size       = 6
    }
  }

  map_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/platform-admins"
      username = "platform-admins"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

See `examples/basic` for a complete root-module example, including a backend block and outputs.

## After apply

```bash
aws eks update-kubeconfig --name my-eks-cluster --region <region>
kubectl get nodes
```

## Notes / things to decide before using in production

- **`cluster_endpoint_public_access_cidrs`** defaults to `0.0.0.0/0`. Lock this down to your office/VPN CIDRs, or set `cluster_endpoint_public_access = false` and rely on private access + a bastion/VPN if the API server shouldn't be reachable from the internet at all.
- **Node group scaling**: `desired_size` is set to ignore changes after creation (`lifecycle.ignore_changes`) so that a Cluster Autoscaler or Karpenter can manage it without Terraform fighting it on every apply. Remove that if you want Terraform to be the sole source of truth for scaling.
- **IRSA**: the OIDC provider is created for you; to actually use IRSA, create an `aws_iam_role` per service account with a trust policy referencing `oidc_provider_arn` / `oidc_provider_url`, and pass the resulting role ARN into a workload's `serviceAccount.annotations["eks.amazonaws.com/role-arn"]` in Kubernetes.
- **Add-on versions**: leaving `version` unset in `enabled_cluster_addons` lets AWS pick the default compatible version. Pin versions explicitly for reproducible upgrades.
- **Networking**: this module does not create a VPC/subnets/NAT gateways — bring your own, or pair it with a VPC module. Node groups need outbound internet access (via NAT or a public subnet) to pull container images unless you're using a fully private setup with VPC endpoints.
