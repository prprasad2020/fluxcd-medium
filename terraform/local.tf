locals {
  namespaces = [
    "argocd",
    "platform-services",
    "cluster-services",
  ]

  priority_classes = {
    cluster-management  = 1000
    cluster-tools       = 500
    monitoring-services = 400
    data                = 300
  }

  apply = [for v in data.kubectl_file_documents.apply.documents : {
    data : yamldecode(v)
    content : v
    }
  ]

  sync = [for v in data.kubectl_file_documents.sync.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
}
