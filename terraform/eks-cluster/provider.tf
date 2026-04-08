terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state — update bucket/key for your account
  backend "s3" {
    bucket         = "YOUR_TERRAFORM_STATE_BUCKET"
    key            = "eks-fastapi/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "eks-fastapi-demo"
      ManagedBy   = "terraform"
      Owner       = "devcarlosfigueiredo"
      Repository  = "https://github.com/devcarlosfigueiredo/eks-fastapi-demo"
    }
  }
}

# kubernetes + helm providers configured after cluster creation
data "aws_eks_cluster"       "cluster" { name = aws_eks_cluster.main.name }
data "aws_eks_cluster_auth"  "cluster" { name = aws_eks_cluster.main.name }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
