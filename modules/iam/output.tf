# Outputs
output "master_role_arn" {
  value = aws_iam_role.master.arn
}

output "worker_role_name" {
  description = "Name of the EKS worker IAM role"
  value       = aws_iam_role.worker.name
}


output "worker_role_arn" {
  value = aws_iam_role.worker.arn
}

# output "alb_controller_role_arn" {
#   value = aws_iam_role.aws_load_balancer_controller.arn
# }

# output "eks_node_additional_policy" {
#   value = aws_iam_policy.eks_node_additional_policy.arn
# }

output "ebs_csi_driver_role_arn" {
  description = "The ARN of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}