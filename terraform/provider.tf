terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "kubernetes" {
  # use KUBECONFIG from environment (~/.kube/config or MINIKUBE)
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

#
provider "aws" {
  region = "us-east-1"


  endpoints {
    ec2        = "http://localhost:5000"
    elbv2      = "http://localhost:5000" # ALB
    cloudfront = "http://localhost:5000"
    wafv2      = "http://localhost:5000"
 }

