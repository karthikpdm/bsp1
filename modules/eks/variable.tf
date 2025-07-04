variable "env" {
  description = "The environment for the infrastructure (e.g., dev, qa, prod)"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "master_role_arn" {
  description = "The ARN of the IAM role for the EKS master"
  type        = string
}

variable "eks_version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "eks_master_sg_id" {
  description = "The security group ID for the EKS master"
  type        = string
}

variable "worker_role_arn" {
  description = "The ARN of the IAM role for the EKS worker nodes"
  type        = string
}

# variable "capacity_type" {
#   description = "The capacity type for the EKS node group (e.g., ON_DEMAND, SPOT)"
#   type        = string
#   default     = "ON_DEMAND"
# }

# variable "disk_size" {
#   description = "The disk size for the EKS worker nodes in GB"
#   type        = number
#   default     = 20
# }

# variable "instance_type" {
#   description = "The instance type for the EKS worker nodes"
#   type        = string
#   default     = "t3.medium"
# }

# variable "ec2_ssh_key_name" {
#   description = "The name of the SSH key pair to access the EC2 instances"
#   type        = string
# }

# variable "ami_type" {
#   description = "The AMI Type for EKS nodes"
#   type        = string
# }

# variable "karpenter_version" {
#   description = "Karpenter Version to be installed"
#   type        = string
# }

# variable "karpenter_vcpu" {
#   description = "Karpenter Maximum CPU Limit"
#   type        = string
# }

# variable "karpenter_memory" {
#   description = "Karpenter Maximum memory Limit"
#   type        = string
# }

variable "account_id" {
  description = "Source Account ID"
  type        = string
}

# variable "desired_size" {
#   description = "The desired number of worker nodes in the EKS node group"
#   type        = number
#   default     = 2
# }

# variable "max_size" {
#   description = "The maximum number of worker nodes in the EKS node group"
#   type        = number
#   default     = 5
# }

# variable "min_size" {
#   description = "The minimum number of worker nodes in the EKS node group"
#   type        = number
#   default     = 1
# }

# variable "max_unavailable" {
#   description = "The maximum number of worker nodes that can be unavailable during updates"
#   type        = number
#   default     = 1
# }

variable "region" {
  description = "The region for the infrastructure (e.g., dev, qa, prod)"
  type        = string
}



variable "ebs_csi_driver_role_arn" {
  description = "The region for the infrastructure (e.g., dev, qa, prod)"
  type        = string
}
# variable "customer_namespace_name" {
#   description = "The customer namespace name"
#   type        = string
# }

# variable "website_namespace_name" {
#   description = "The website namespace name"
#   type        = string
# }

# variable "internal_namespace_name" {
#   description = "The internal namespace name"
#   type        = string
# }

variable "map_tagging" {
  description = "MAP tagging for all the resources"
  type        = map(string)
}

# variable "eks_node_additional_policy" {
#   description = "EKS Node Additional policy ARN"
#   type        = string
# }

variable "metrics_server_version" {
  type          = string
  description   = "Metrics Server Version"
}
