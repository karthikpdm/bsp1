# variables.tf


variable "project_name" {
  description = "region (e.g., dev, qa, prod)"
  type        = string
}
variable "region" {
  description = "region (e.g., dev, qa, prod)"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

# variable "desired_size" {
#   description = "Desired number of worker nodes"
#   type        = number
# }

# variable "max_size" {
#   description = "Maximum number of worker nodes"
#   type        = number
# }

# variable "min_size" {
#   description = "Minimum number of worker nodes"
#   type        = number
# }

# variable "disk_size" {
#   description = "Size of the EBS volume for each node in GB"
#   type        = number
# }

# variable "max_unavailable" {
#   description = "Size of the EBS volume for each node in GB"
#   type        = number
# }
# variable "instance_type" {
#   description = "EC2 instance type for the EKS nodes"
#   type        = string
# }

# variable "ami_type" {
#   description = "AMI Type for the EKS worker nodes"
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

variable "master_ingress_rules" {
  description = "List of ingress rules for the EKS master security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "master_egress_rules" {
  description = "List of egress rules for the EKS master security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "map_tagging" {
  description = "Mandatory tags for all the resources"
  type        = map(string)
}

variable "workers_ingress_rules" {
  description = "List of ingress rules for the EKS workers security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "workers_egress_rules" {
  description = "List of egress rules for the EKS workers security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}


variable "metrics_server_version" {
  type          = string
  description   = "Metrics Server Version"
}



