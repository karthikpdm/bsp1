output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.eks.arn
}

output "eks_cluster_version" {
  description = "The version of the EKS cluster"
  value       = aws_eks_cluster.eks.version
}

output "eks_cluster_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# output "eks_node_group_name" {
#   description = "The name of the EKS node group"
#   value       = aws_eks_node_group.node-grp.node_group_name
# }

# output "eks_node_group_arn" {
#   description = "The ARN of the EKS node group"
#   value       = aws_eks_node_group.node-grp.arn
# }

# output "eks_node_group_capacity_type" {
#   description = "The capacity type of the EKS node group"
#   value       = aws_eks_node_group.node-grp.capacity_type
# }

output "vpc_id" {
  description = "The ID of the existing VPC"
  value       = data.aws_vpc.existing_vpc.id
}

# output "private_subnet_az1_id" {
#   description = "The ID of the first private subnet in AZ1"
#   value       = data.aws_subnet.private_subnet_az1.id
# }

# output "private_subnet_az2_id" {
#   description = "The ID of the second private subnet in AZ2"
#   value       = data.aws_subnet.private_subnet_az2.id
# }

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_ca_certificate" {
  description = "Certificate authority data for the cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "oidc_provider_url" {
  value = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}