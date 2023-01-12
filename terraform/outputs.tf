output "cluster_oidc_issuer" {
  value = module.eks.cluster_oidc_issuer[0]
}
