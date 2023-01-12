resource "aws_kms_key" "eks" {
  description         = "Development eks cluster encryption key"
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = "true"
}

resource "aws_kms_alias" "eks" {
  name          = "alias/development-eks-cluster"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_security_group" "additional_cluster_sg" {
  name        = "development-cluster-additional-sg"
  description = "Additional security group for development kubernetes cluster"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name = "development-cluster-additional-sg"
  }
}

#Allow staging to run atlantis
resource "aws_security_group_rule" "allow_stage" {
  security_group_id = aws_security_group.additional_cluster_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.1.0.0/16"]
}

resource "aws_security_group_rule" "allow_vpn_ingress" {
  security_group_id = aws_security_group.additional_cluster_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.30.0.0/16"]
}

resource "aws_security_group_rule" "ingress_allow_worker" {
  security_group_id        = aws_security_group.additional_cluster_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker.id
}

resource "aws_cloudwatch_log_group" "eks_logs" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/development-cluster/cluster"
  retention_in_days = 7
}

module "eks" {
  source = "../../../../../../vendor/aws-eks-new/aws/aws-eks"

  cluster_name                    = "development-cluster"
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  cluster_enabled_log_types = ["scheduler", "audit", "authenticator", "api"]

  subnet_ids                    = data.terraform_remote_state.network.outputs.private_subnets
  vpc_id                        = data.terraform_remote_state.network.outputs.vpc_id
  additional_security_group_ids = [aws_security_group.additional_cluster_sg.id]

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::443916343631:user/tliyanage"
      username = "tliyanage"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::443916343631:user/mdayyeh"
      username = "mdayyeh"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::443916343631:user/hfaouri"
      username = "hfaouri"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::443916343631:user/paluthge"
      username = "paluthge"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::443916343631:role/admin"
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::443916343631:role/product-team"
      username = "product-team"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::443916343631:role/product-team-admin"
      username = "product-team-admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::443916343631:role/atlantis-provisioning-role"
      username = "atlantis"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::443916343631:role/AmazonEKSNodeRole"
      username = "system:node:{{EC2PrivateDNSName}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "arn:aws:iam::443916343631:role/eks-worker"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
  ]
}

resource "kubernetes_priority_class" "priority_class" {
  for_each = local.priority_classes

  value = each.value

  metadata {
    name = each.key
  }
}

resource "kubernetes_namespace" "namespace" {
  for_each = toset(local.namespaces)

  metadata {
    name = each.value
  }
}
