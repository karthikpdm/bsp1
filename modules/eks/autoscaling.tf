# resource "kubernetes_namespace" "autoscaling" {
#   metadata {
#     name = "autoscaling"
#   }
# }

# data "aws_partition" "current" {}

# resource "aws_iam_role" "karpenter" {
#   name = "KarpenterRole-${var.project_name}-eks-cluster-${var.env}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         "Effect": "Allow"
#         "Principal": {
#           "Service": "ec2.amazonaws.com"
#         }
#         "Action": "sts:AssumeRole",
#         "Condition": {
#           "StringEquals": {
#             "aws:SourceAccount": "${var.account_id}"
#           }
#         }
#       },
#       {
#         "Action": "sts:AssumeRoleWithWebIdentity",
#         "Condition": {
#           "StringEquals": {
#             "${local.provider_url_oidc}:sub": "system:serviceaccount:${kubernetes_namespace.autoscaling.id}:karpenter"
#           },
#           "StringLike": {
#             "${local.provider_url_oidc}:aud": "sts.amazonaws.com"
#           }
#         }
#         "Effect": "Allow",
#         "Principal": {
#           "Federated": "arn:${local.partition}:iam::${local.aws_account_id}:oidc-provider/${local.provider_url_oidc}"
#         }
#       }
#     ]
#   })
  
#   tags = merge(
#     { "Name"    = "KarpenterRole-${var.project_name}-eks-cluster-${var.env}" },
#     var.map_tagging
#   )
# }

# resource "aws_iam_role_policy" "karpenter_contoller" {
#   name = "KarpenterPolicy-${var.project_name}-eks-cluster-${var.env}"
#   role = aws_iam_role.karpenter.id

#   policy = jsonencode({
#     Version   = "2012-10-17"
#     Statement = [
#       {
#         "Action": [
#           "ssm:GetParameter",
#           "ec2:DescribeImages",
#           "ec2:RunInstances",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeLaunchTemplates",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeInstanceTypeOfferings",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DeleteLaunchTemplate",
#           "ec2:CreateTags",
#           "ec2:CreateLaunchTemplate",
#           "ec2:CreateFleet",
#           "ec2:DescribeSpotPriceHistory",
#           "pricing:GetProducts"
#         ]
#         "Effect": "Allow"
#         "Resource": "*"
#         "Sid": "Karpenter"
#       },
#       {
#         "Action": "ec2:TerminateInstances",
#         "Condition": {
#           "StringLike": {
#             "ec2:ResourceTag/karpenter.sh/nodepool": "*"
#           }
#         },
#         "Effect": "Allow",
#         "Resource": "*",
#         "Sid": "ConditionalEC2Termination"
#       },
#       {
#         "Effect": "Allow",
#         "Action": "iam:PassRole",
#         "Resource": "${aws_iam_role.karpenter.arn}",
#         "Sid": "PassNodeIAMRole"
#       },
#       {
#         "Effect": "Allow",
#         "Action": "eks:DescribeCluster",
#         "Resource": "${aws_eks_cluster.eks.arn}",
#         "Sid": "EKSClusterEndpointLookup"
#       },
#       {
#         "Sid": "AllowScopedInstanceProfileCreationActions",
#         "Effect": "Allow",
#         "Resource": "*",
#         "Action": [
#           "iam:CreateInstanceProfile"
#         ]
#       },
#       {
#         "Sid": "AllowScopedInstanceProfileTagActions",
#         "Effect": "Allow",
#         "Resource": "*",
#         "Action": [
#           "iam:TagInstanceProfile"
#         ]
#       },
#       {
#         "Sid": "AllowScopedInstanceProfileActions",
#         "Effect": "Allow",
#         "Resource": "*",
#         "Action": [
#           "iam:AddRoleToInstanceProfile",
#           "iam:RemoveRoleFromInstanceProfile",
#           "iam:DeleteInstanceProfile"
#         ]
#       },
#       {
#         "Sid": "AllowInstanceProfileReadActions",
#         "Effect": "Allow",
#         "Resource": "*",
#         "Action": "iam:GetInstanceProfile"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "container_readonly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.karpenter.name
# }

# resource "aws_iam_role_policy_attachment" "worker_node" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.karpenter.name
# }

# resource "aws_iam_role_policy_attachment" "eks_cni" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.karpenter.name
# }

# resource "aws_iam_role_policy_attachment" "ssm_managedinstance" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.karpenter.name
# }

# resource "aws_iam_role_policy_attachment" "ssm_patch" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
#   role       = aws_iam_role.karpenter.name
# }

# # resource "aws_iam_role_policy_attachment" "eks_node_additional_policy" {
# #   policy_arn = "${var.eks_node_additional_policy}"
# #   role       = aws_iam_role.karpenter.name
# # }

# resource "helm_release" "karpenter" {
#   chart      = "oci://public.ecr.aws/karpenter/karpenter"
#   name       = "karpenter"
#   version    = var.karpenter_version

#   namespace = kubernetes_namespace.autoscaling.id
  
#   timeout = 600
  
#   set {
#     name = "settings.clusterName"
#     value = aws_eks_cluster.eks.name
#   }

#   values = [
#     local.karpenter_yaml,
#   ]

# }

# resource "kubernetes_manifest" "karpenter-nodepool" {
  
#   manifest = yamldecode(local.karpenter_nodepool_yaml)

#   depends_on = [
#     helm_release.karpenter,
#     aws_eks_cluster.eks,
#     aws_eks_node_group.node-grp]
# }

# resource "kubernetes_manifest" "karpenter-nodeclass" {
  
#   manifest = yamldecode(local.karpenter_nodeclass_yaml)

#   depends_on = [
#     helm_release.karpenter,
#     aws_eks_cluster.eks,
#     aws_eks_node_group.node-grp,
#     kubernetes_manifest.karpenter-nodepool]
# }

