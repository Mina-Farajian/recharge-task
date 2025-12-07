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
  # 1. Credentials (Fake but required for initialization)
  region                  = "us-east-1"
  access_key              = "mock_access_key"
  secret_key              = "mock_secret_key"

  # 2. Skip Validation (Essential for Moto)
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # 3. Use the Minikube IP variable (must be correct)
  endpoints {
    ec2        = "http://${var.minikube_ip}:5000"
    elbv2      = "http://${var.minikube_ip}:5000"
    cloudfront = "http://${var.minikube_ip}:5000"
    wafv2      = "http://${var.minikube_ip}:5000"
  }
}
