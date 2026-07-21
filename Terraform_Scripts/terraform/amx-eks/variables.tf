variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where the cluster and worker nodes will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS control plane ENIs and node groups (should span multiple AZs, typically private subnets)"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "List of control plane log types to enable (api, audit, authenticator, controllerManager, scheduler)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention in days for EKS control plane logs"
  type        = number
  default     = 90
}

variable "enabled_cluster_addons" {
  description = "Map of EKS add-ons to install, keyed by add-on name, with optional version override"
  type = map(object({
    version                  = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string)
  }))
  default = {
    "vpc-cni" = {}
    "coredns" = {}
    "kube-proxy" = {}
  }
}

variable "node_groups" {
  description = "Map of managed node group definitions"
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND") # ON_DEMAND or SPOT
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    disk_size      = optional(number, 50)
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    subnet_ids = optional(list(string)) # falls back to var.subnet_ids if not set
  }))
  default = {
    default = {
      instance_types = ["m5.large"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4
    }
  }
}

variable "tags" {
  description = "Common tags applied to all resources created by this module"
  type        = map(string)
  default     = {}
}

variable "map_roles" {
  description = "Additional IAM role ARNs to map into the aws-auth ConfigMap, e.g. [{ rolearn = \"...\", username = \"...\", groups = [\"system:masters\"] }]"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
