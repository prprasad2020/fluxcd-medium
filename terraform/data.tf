data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "flux_install" "main" {
  target_path    = "clusters/development"
  network_policy = false
  components     = ["source-controller", "helm-controller", "kustomize-controller"]
  version        = "latest"
}

data "kubectl_file_documents" "apply" {
  content = data.flux_install.main.content
}

data "flux_sync" "main" {
  target_path = "clusters/development"
  url         = "https://gitlab.com/alteos/infrastructure/platform/cluster-services"
  branch      = "master"
}

data "kubectl_file_documents" "sync" {
  content = data.flux_sync.main.content
}

data "aws_secretsmanager_secret_version" "flux" {
  secret_id = "arn:aws:secretsmanager:eu-central-1:443916343631:secret:flux-token-QoWotY"
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "terraform-state-org-alteos-dev"
    key     = "network/terraform.tfstate"
    key     = "org/alteos/development/eu-central-1/networking.tfstate"
    region  = "eu-central-1"
    profile = "prod"
  }
}
