###########################################################################################################
# Creating IAM role for Worker Node
###########################################################################################################


# IAM role for Worker Node
resource "aws_iam_role" "worker" {
  name = "${var.project_name}-eks-worker-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = merge(
    { "Name"    = "${var.project_name}-eks-worker-role-${var.env}" },
    var.map_tagging
  )
}

# resource "aws_iam_policy" "eks_node_additional_policy" {
#   name = "${var.project_name}-eks-node-additional-policy-${var.env}"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "NodePolicy",
#         Effect = "Allow"
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:CreateTags"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid     = "DynamoDBPolicy"
#         Effect  = "Allow",
#         Action  = [
#           "dynamodb:PutItem",
#           "dynamodb:GetItem",
#           "dynamodb:UpdateItem",
#           "dynamodb:DeleteItem",
#           "dynamodb:BatchGetItem",
#           "dynamodb:BatchWriteItem",
#           "dynamodb:Query",
#           "dynamodb:Scan",
#           "dynamodb:PartiQLSelect",
#           "dynamodb:PartiQLInsert",
#           "dynamodb:PartiQLUpdate",
#           "dynamodb:PartiQLDelete"
#         ],
#         Resource  = var.eks_dynamodb_arns
#       },
#       {
#         Sid     = "S3Policy"
#         Effect  = "Allow",
#         Action  = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:DeleteObject"
#         ],
#         Resource  = var.eks_s3_bucket_arns
#       },
#       {
#         Sid     = "SecretsManagerPolicy"
#         Effect  = "Allow",
#         Action  = [
#           "secretsmanager:GetSecretValue"
#         ],
#         Resource  = var.eks_secret_manage_arns
#       },
#       {
#         Sid     = "KMSPolicy"
#         Effect  = "Allow",
#         Action  = [
#           "kms:Decrypt",
#           "kms:DescribeKey",
#           "kms:GenerateDataKey"
#         ],
#         Resource  = var.eks_kms_arns
#       },
#       {
#         Sid     = "ECRPolicy"
#         Effect  = "Allow",
#         Action  = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ],
#         Resource  = "*"
#       }
      
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "x-ray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "eks_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.worker.name
}

# resource "aws_iam_role_policy_attachment" "eks_node_additional_policy" {
#   policy_arn = aws_iam_policy.eks_node_additional_policy.arn
#   role       = aws_iam_role.worker.name
# }

resource "aws_iam_instance_profile" "worker" {
  name = "${var.project_name}-eks-worker-profile-${var.env}"
  role = aws_iam_role.worker.name

  tags = merge(
    { "Name"    = "${var.project_name}-eks-worker-profile-${var.env}" },
    var.map_tagging
  )
}