terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "0.20.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "test-eks"
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "test-eks"
}

provider "aws" {
  region = var.region
}
