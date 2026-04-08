variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-fastapi-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "environment" {
  description = "Deployment environment (dev | staging | production)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups"
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "myapp-dev"
}

variable "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  type        = string
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "eks-fastapi-demo"
    ManagedBy = "terraform"
    Owner     = "devcarlosfigueiredo"
  }
}
