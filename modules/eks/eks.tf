
# Data sources for existing VPC components

#####################################################################################################################

data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["pw-vpc-${var.env}"]
  }
}

data "aws_subnet" "private_subnet_az1" {
  filter {
    name   = "tag:Name"
    values = ["pw-private-subnet-az1-${var.env}"]
  }
}

data "aws_subnet" "private_subnet_az2" {
  filter {
    name   = "tag:Name"
    values = ["pw-private-subnet-az2-${var.env}"]
  }
}

data "aws_subnet" "public_subnet_az1" {
  filter {
    name   = "tag:Name"
    values = ["pw-public-subnet-az1-${var.env}"]  
  }
}

data "aws_subnet" "public_subnet_az2" {
  filter {
    name   = "tag:Name"
    values = ["pw-public-subnet-az2-${var.env}"]  
  }
}


# Get current caller identity and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster_auth" "pw_eks" {
  name = aws_eks_cluster.eks.name
}

# data "aws_kms_key" "cloudwatch-log-group" {
#   key_id = "alias/accelerator/kms/cloudwatch/key"
# }


#####################################################################################################################
                                                # access 
#####################################################################################################################

# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.pw_eks.token
# }

# # Helm provider for older versions (1.x)
# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.pw_eks.token
#   }
# }





# # Access entry for your admin user
# resource "aws_eks_access_entry" "admin_access" {
#   cluster_name      = aws_eks_cluster.eks.name
#   principal_arn     = data.aws_caller_identity.current.arn
#   kubernetes_groups = ["system:masters"]
#   type             = "STANDARD"

#   tags = var.map_tagging
# }

# # Access entry for node groups (if you have managed node groups)
# resource "aws_eks_access_entry" "node_group_access" {
#   count = var.node_group_role_arn != null ? 1 : 0
  
#   cluster_name  = aws_eks_cluster.eks.name
#   principal_arn = var.node_group_role_arn
#   type         = "EC2_LINUX"

#   tags = var.map_tagging
# }

# # Providers with exec authentication
# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name, "--region", data.aws_region.current.name]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name, "--region", data.aws_region.current.name]
#     }
#   }
# }

######################################################################################################################################
##############################################Creating EKS Cluster####################################################################
######################################################################################################################################


# Creating EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "${var.project_name}-eks-cluster-${var.env}"
  role_arn = var.master_role_arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [var.eks_master_sg_id]
  }

  # Enable all log types
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    # authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  
  # encryption_config {
  #   provider {
  #     key_arn = aws_kms_key.eks_secrets.arn
  #   }
  #   resources = ["secrets"]
  # }

  # Ensure that CloudWatch log group is created before the EKS cluster
  depends_on = [aws_cloudwatch_log_group.eks_cluster]

  tags = merge(
    { "Name"    = "${var.project_name}-eks-cluster-${var.env}" },
    var.map_tagging
  )
  
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Create CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.project_name}-cluster-${var.env}/cluster"
  retention_in_days = 365
  
  # kms_key_id  = data.aws_kms_key.cloudwatch-log-group.arn
  
  tags = merge(
    { "Name"    = "${var.project_name}-eks-cluster-logs-${var.env}" },
    var.map_tagging
  )
}




########################################################################################################################################################################

########################################################### eks addons ################################################################################################

########################################################################################################################################################################

data "aws_eks_addon_version" "vpc-cni-default" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.eks.version
}

resource "aws_eks_addon" "vpc-cni" {
  addon_name        = "vpc-cni"
  addon_version     = data.aws_eks_addon_version.vpc-cni-default.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  cluster_name      = aws_eks_cluster.eks.name
  
  configuration_values = jsonencode({
    "enableNetworkPolicy" = "true"
  })
}





data "aws_eks_addon_version" "kube-proxy-default" {
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.eks.version
}

resource "aws_eks_addon" "kube-proxy" {
  addon_name        = "kube-proxy"
  addon_version     = data.aws_eks_addon_version.kube-proxy-default.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  cluster_name      = aws_eks_cluster.eks.name

}





data "aws_eks_addon_version" "coredns-default" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.eks.version
}

resource "aws_eks_addon" "coredns" {
  addon_name        = "coredns"
  addon_version     = data.aws_eks_addon_version.coredns-default.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  cluster_name      = aws_eks_cluster.eks.name

}

#######################################################################
#oidc 

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  
  tags = var.map_tagging
}



#######################################################################

# EBS CSI Driver addon
data "aws_eks_addon_version" "ebs-csi-driver-default" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.eks.version
}


resource "aws_eks_addon" "ebs-csi-driver" {
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs-csi-driver-default.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  cluster_name             = aws_eks_cluster.eks.name
  service_account_role_arn = var.ebs_csi_driver_role_arn
}