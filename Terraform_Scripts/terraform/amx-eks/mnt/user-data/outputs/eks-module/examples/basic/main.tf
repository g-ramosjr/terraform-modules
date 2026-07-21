terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    # bucket, key, region, dynamodb_table typically supplied via -backend-config
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs across multiple AZs for the cluster and node groups"
  type        = list(string)
}

module "eks" {
  source = "../../" # points at the module root; replace with a git source ref when reused elsewhere

  cluster_name        = "my-eks-cluster"
  kubernetes_version  = "1.29"
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      labels = {
        role = "system"
      }
    }
    workers = {
      instance_types = ["m5.xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 3
      min_size       = 1
      max_size       = 6
      labels = {
        role = "workers"
      }
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
    Team        = "platform"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  value = module.eks.kubeconfig_command
}
