locals {
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
