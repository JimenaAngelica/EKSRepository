
//ROL EKS CLUSTER
resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-iam-role-${var.environment}"
  path = "/"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"

      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role" "eks-nodes-role" {
  name = "eks-nodes-role-${var.environment}"
  path = "/"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"

      }
    ]
  }
  POLICY
}

//ROL NODE GROUPS
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-nodes-role.name
}

 resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role    = aws_iam_role.eks-nodes-role.name
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role    = aws_iam_role.eks-nodes-role.name
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role    = aws_iam_role.eks-nodes-role.name
 }

resource "aws_eks_cluster" "eks-cluster-services" {
 name = "eks-cluster-${var.environment}"
 role_arn = aws_iam_role.eks-cluster-role.arn

 vpc_config {
  subnet_ids = [var.subnet_id_1, var.subnet_id_2]
 }

 depends_on = [
  aws_iam_role.eks-cluster-role,
 ]
}

 resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.eks-cluster-services.name
  node_group_name = "eks-cluster-workernodes-${var.environment}"
  node_role_arn  = aws_iam_role.eks-nodes-role.arn
  subnet_ids   = [var.subnet_id_1, var.subnet_id_2]
  instance_types = ["t2.small"]
 
  scaling_config {
   desired_size = 1
   max_size   = 1
   min_size   = 1
  }
 
  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
 }
