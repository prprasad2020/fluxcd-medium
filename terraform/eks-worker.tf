resource "aws_security_group" "eks_worker" {
  name        = "eks-cluster"
  description = "Security group for eks worker nodes"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name = "eks-cluster"
  }
}

resource "aws_security_group_rule" "ingress_allow_vpn" {
  security_group_id = aws_security_group.eks_worker.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.30.0.0/16"]
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.eks_worker.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "eks_worker" {
  name = "eks-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_container" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker.name
}

module "node_group_0" {
  source = "../../../../../../vendor/aws-eks-worker/aws/aws-eks-worker"

  ami_id                 = "ami-0241d3166f8e974f0"
  bootstrap_extra_args   = "--use-max-pods false --kubelet-extra-args --node-labels=node.kubernetes.io/role=worker"
  cluster_ca_cert        = module.eks.cluster_certificate_authority_data
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_name           = module.eks.cluster_id
  key_name               = "develop"
  name                   = "worker-group-1"
  node_role              = aws_iam_role.eks_worker.arn
  subnet_ids             = data.terraform_remote_state.network.outputs.private_subnets
  vpc_security_group_ids = [aws_security_group.eks_worker.id]

  autoscaling_config = {
    desired_size = 2
    min_size     = 1
    max_size     = 20
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_container,
    aws_iam_role_policy_attachment.eks_worker,
  ]
}
