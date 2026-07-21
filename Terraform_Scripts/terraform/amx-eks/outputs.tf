output "cluster_id" {
  description = "EKS cluster ID/name"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the cluster (used in kubeconfig)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane ENIs"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA role trust policies"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC issuer (without https://), for use in IRSA trust policy conditions"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN used by the EKS control plane"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN used by worker nodes (attach additional policies to this if needed)"
  value       = aws_iam_role.node.arn
}

output "node_group_ids" {
  description = "Map of node group keys to their EKS node group IDs"
  value       = { for k, ng in aws_eks_node_group.this : k => ng.id }
}

output "node_group_status" {
  description = "Map of node group keys to their current status"
  value       = { for k, ng in aws_eks_node_group.this : k => ng.status }
}

output "kubeconfig_command" {
  description = "Convenience CLI command to update your local kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region <region>"
}
