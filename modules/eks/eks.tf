
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








# Data sources for existing VPC components

# #####################################################################################################################

# data "aws_vpc" "existing_vpc" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-vpc-${var.env}"]
#   }
# }

# data "aws_subnet" "private_subnet_az1" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-private-subnet-az1-${var.env}"]
#   }
# }

# data "aws_subnet" "private_subnet_az2" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-private-subnet-az2-${var.env}"]
#   }
# }

# data "aws_subnet" "public_subnet_az1" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-public-subnet-az1-${var.env}"]  
#   }
# }

# data "aws_subnet" "public_subnet_az2" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-public-subnet-az2-${var.env}"]  
#   }
# }


# # Get current caller identity and region
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# data "aws_eks_cluster_auth" "pw_eks" {
#   name = aws_eks_cluster.eks.name
# }

# # data "aws_kms_key" "cloudwatch-log-group" {
# #   key_id = "alias/accelerator/kms/cloudwatch/key"
# # }


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
# Data sources for existing VPC components

# #####################################################################################################################

# data "aws_vpc" "existing_vpc" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-vpc-${var.env}"]
#   }
# }

# data "aws_subnet" "private_subnet_az1" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-private-subnet-az1-${var.env}"]
#   }
# }

# data "aws_subnet" "private_subnet_az2" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-private-subnet-az2-${var.env}"]
#   }
# }

# data "aws_subnet" "public_subnet_az1" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-public-subnet-az1-${var.env}"]  
#   }
# }

# data "aws_subnet" "public_subnet_az2" {
#   filter {
#     name   = "tag:Name"
#     values = ["bsp-public-subnet-az2-${var.env}"]  
#   }
# }


# # Get current caller identity and region
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# data "aws_eks_cluster_auth" "pw_eks" {
#   name = aws_eks_cluster.eks.name
# }




# # Creating EKS Cluster
# resource "aws_eks_cluster" "eks" {
#   name     = "${var.project_name}-eks-cluster-${var.env}"
#   role_arn = var.master_role_arn
#   version  = var.eks_version

#   vpc_config {
#     subnet_ids              = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]
#     endpoint_private_access = true
#     endpoint_public_access  = true
#     security_group_ids      = [var.eks_master_sg_id]
#   }

#   # Enable all log types
#   enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

#   access_config {
#     authentication_mode = "API_AND_CONFIG_MAP"
#     # authentication_mode = "API"
#     bootstrap_cluster_creator_admin_permissions = true
#   }
  
#   # encryption_config {
#   #   provider {
#   #     key_arn = aws_kms_key.eks_secrets.arn
#   #   }
#   #   resources = ["secrets"]
#   # }

#   # Ensure that CloudWatch log group is created before the EKS cluster
#   depends_on = [aws_cloudwatch_log_group.eks_cluster]

#   tags = merge(
#     { "Name"    = "${var.project_name}-eks-cluster-${var.env}" },
#     var.map_tagging
#   )
  
#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }

# # Create CloudWatch Log Group for EKS cluster logs
# resource "aws_cloudwatch_log_group" "eks_cluster" {
#   name              = "/aws/eks/${var.project_name}-cluster-${var.env}/cluster"
#   retention_in_days = 365
  
#   # kms_key_id  = data.aws_kms_key.cloudwatch-log-group.arn
  
#   tags = merge(
#     { "Name"    = "${var.project_name}-eks-cluster-logs-${var.env}" },
#     var.map_tagging
#   )
# }




# ########################################################################################################################################################################

# ########################################################### eks addons ################################################################################################

# ########################################################################################################################################################################

# data "aws_eks_addon_version" "vpc-cni-default" {
#   addon_name         = "vpc-cni"
#   kubernetes_version = aws_eks_cluster.eks.version
# }

# resource "aws_eks_addon" "vpc-cni" {
#   addon_name        = "vpc-cni"
#   addon_version     = data.aws_eks_addon_version.vpc-cni-default.version
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   cluster_name      = aws_eks_cluster.eks.name
  
#   configuration_values = jsonencode({
#     "enableNetworkPolicy" = "true"
#   })
# }





# data "aws_eks_addon_version" "kube-proxy-default" {
#   addon_name         = "kube-proxy"
#   kubernetes_version = aws_eks_cluster.eks.version
# }

# resource "aws_eks_addon" "kube-proxy" {
#   addon_name        = "kube-proxy"
#   addon_version     = data.aws_eks_addon_version.kube-proxy-default.version
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   cluster_name      = aws_eks_cluster.eks.name

# }





# data "aws_eks_addon_version" "coredns-default" {
#   addon_name         = "coredns"
#   kubernetes_version = aws_eks_cluster.eks.version
# }

# resource "aws_eks_addon" "coredns" {
#   addon_name        = "coredns"
#   addon_version     = data.aws_eks_addon_version.coredns-default.version
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   cluster_name      = aws_eks_cluster.eks.name

# }

# #######################################################################
# #oidc 

# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  
#   tags = var.map_tagging
# }



# #######################################################################

# # EBS CSI Driver addon
# data "aws_eks_addon_version" "ebs-csi-driver-default" {
#   addon_name         = "aws-ebs-csi-driver"
#   kubernetes_version = aws_eks_cluster.eks.version
# }


# resource "aws_eks_addon" "ebs-csi-driver" {
#   addon_name               = "aws-ebs-csi-driver"
#   addon_version            = data.aws_eks_addon_version.ebs-csi-driver-default.version
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   cluster_name             = aws_eks_cluster.eks.name
#   service_account_role_arn = var.ebs_csi_driver_role_arn
# }
















########################################################################################################################################################################
########################################################### AMP (Amazon Managed Prometheus) Monitoring ################################################################
########################################################################################################################################################################

# Create Amazon Managed Prometheus Workspace
resource "aws_prometheus_workspace" "eks_monitoring" {
  alias = "${var.project_name}-eks-prometheus-${var.env}"
  
  tags = merge(
    { "Name" = "${var.project_name}-eks-prometheus-${var.env}" },
    var.map_tagging
  )
}

# IAM Role for Grafana Workspace
resource "aws_iam_role" "grafana_role" {
  name = "${var.project_name}-grafana-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    { "Name" = "${var.project_name}-grafana-role-${var.env}" },
    var.map_tagging
  )
}

# IAM Policy for Grafana to access Prometheus
resource "aws_iam_policy" "grafana_prometheus_policy" {
  name        = "${var.project_name}-grafana-prometheus-policy-${var.env}"
  description = "IAM policy for Grafana to access Prometheus"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    { "Name" = "${var.project_name}-grafana-prometheus-policy-${var.env}" },
    var.map_tagging
  )
}

# Attach policy to Grafana role
resource "aws_iam_role_policy_attachment" "grafana_prometheus_policy" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.grafana_prometheus_policy.arn
}

# Security Group for Grafana
resource "aws_security_group" "grafana_sg" {
  name        = "${var.project_name}-grafana-sg-${var.env}"
  description = "Security group for Grafana workspace"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { "Name" = "${var.project_name}-grafana-sg-${var.env}" },
    var.map_tagging
  )
}

# Create Amazon Managed Grafana Workspace
resource "aws_grafana_workspace" "eks_monitoring" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana_role.arn
  name                     = "${var.project_name}-eks-grafana-${var.env}"
  description              = "Grafana workspace for EKS monitoring"
  
  data_sources = ["PROMETHEUS"]
  
  # Use existing VPC and subnets
  vpc_configuration {
    security_group_ids = [aws_security_group.grafana_sg.id]
    subnet_ids = [
      data.aws_subnet.private_subnet_az1.id,
      data.aws_subnet.private_subnet_az2.id
    ]
  }
  
  tags = merge(
    { "Name" = "${var.project_name}-eks-grafana-${var.env}" },
    var.map_tagging
  )
}

# IAM Role for Prometheus Service Account (IRSA)
resource "aws_iam_role" "prometheus_service_account" {
  name = "${var.project_name}-eks-prometheus-sa-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:otel-collector"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    { "Name" = "${var.project_name}-eks-prometheus-sa-role-${var.env}" },
    var.map_tagging
  )
}

# IAM Policy for Prometheus Service Account
resource "aws_iam_policy" "prometheus_service_account" {
  name        = "${var.project_name}-eks-prometheus-sa-policy-${var.env}"
  description = "IAM policy for Prometheus service account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:QueryMetrics"
        ]
        Resource = aws_prometheus_workspace.eks_monitoring.arn
      }
    ]
  })

  tags = merge(
    { "Name" = "${var.project_name}-eks-prometheus-sa-policy-${var.env}" },
    var.map_tagging
  )
}

# Attach policy to Prometheus service account role
resource "aws_iam_role_policy_attachment" "prometheus_service_account" {
  role       = aws_iam_role.prometheus_service_account.name
  policy_arn = aws_iam_policy.prometheus_service_account.arn
}

# Remove ADOT addon - we don't need it for our use case
# Our standalone OTEL collector handles everything we need

# Create namespace for monitoring
resource "kubernetes_namespace" "amazon_cloudwatch" {
  depends_on = [aws_eks_cluster.eks]
  
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

# OpenTelemetry Collector ConfigMap for AMP
resource "kubernetes_config_map" "otel_collector_config" {
  depends_on = [kubernetes_namespace.amazon_cloudwatch]
  
  metadata {
    name      = "otel-collector-config"
    namespace = "amazon-cloudwatch"
  }

  data = {
    "config.yaml" = yamlencode({
      receivers = {
        prometheus = {
          config = {
            global = {
              scrape_interval = "30s"
            }
            scrape_configs = [
              {
                job_name = "kube-state-metrics"
                static_configs = [{
                  targets = ["kube-state-metrics.amazon-cloudwatch.svc.cluster.local:8080"]
                }]
                scrape_interval = "30s"
                metrics_path = "/metrics"
              }
            ]
          }
        }
      }
      processors = {
        batch = {
          timeout = "1s"
          send_batch_size = 1024
        }
        resource = {
          attributes = [
            {
              key = "cluster_name"
              value = aws_eks_cluster.eks.name
              action = "insert"
            },
            {
              key = "region"
              value = data.aws_region.current.name
              action = "insert"
            }
          ]
        }
      }
      exporters = {
        prometheusremotewrite = {
          endpoint = "${aws_prometheus_workspace.eks_monitoring.prometheus_endpoint}api/v1/remote_write"
          auth = {
            authenticator = "sigv4auth"
          }
        }
        logging = {
          loglevel = "debug"
        }
      }
      extensions = {
        sigv4auth = {
          region = data.aws_region.current.name
          service = "aps"
        }
        health_check = {
          endpoint = "0.0.0.0:13133"
        }
      }
      service = {
        extensions = ["health_check", "sigv4auth"]
        pipelines = {
          metrics = {
            receivers = ["prometheus"]
            processors = ["batch", "resource"]
            exporters = ["prometheusremotewrite", "logging"]
          }
        }
      }
    })
  }
}

# Create Service Account for OpenTelemetry Collector
resource "kubernetes_service_account" "otel_collector" {
  depends_on = [kubernetes_namespace.amazon_cloudwatch]
  
  metadata {
    name      = "otel-collector"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_service_account.arn
    }
  }
}

# Create ClusterRole for OpenTelemetry Collector
resource "kubernetes_cluster_role" "otel_collector" {
  metadata {
    name = "otel-collector-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

# Create ClusterRoleBinding for OpenTelemetry Collector
resource "kubernetes_cluster_role_binding" "otel_collector" {
  metadata {
    name = "otel-collector-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.otel_collector.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.otel_collector.metadata[0].name
    namespace = kubernetes_service_account.otel_collector.metadata[0].namespace
  }
}

# Deploy kube-state-metrics
resource "kubernetes_deployment" "kube_state_metrics" {
  depends_on = [kubernetes_namespace.amazon_cloudwatch]
  
  metadata {
    name      = "kube-state-metrics"
    namespace = "amazon-cloudwatch"
    labels = {
      app = "kube-state-metrics"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kube-state-metrics"
      }
    }

    template {
      metadata {
        labels = {
          app = "kube-state-metrics"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.kube_state_metrics.metadata[0].name
        
        container {
          name  = "kube-state-metrics"
          image = "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.0"
          
          port {
            container_port = 8080
            name          = "http-metrics"
          }

          port {
            container_port = 8081
            name          = "telemetry"
          }

          args = [
            "--port=8080",
            "--telemetry-port=8081"
          ]

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8081
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
          }
        }
      }
    }
  }
}

# Service Account for kube-state-metrics
resource "kubernetes_service_account" "kube_state_metrics" {
  depends_on = [kubernetes_namespace.amazon_cloudwatch]
  
  metadata {
    name      = "kube-state-metrics"
    namespace = "amazon-cloudwatch"
  }
}

# ClusterRole for kube-state-metrics
resource "kubernetes_cluster_role" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  rule {
    api_groups = [""]
    resources = [
      "configmaps",
      "secrets",
      "nodes",
      "pods",
      "services",
      "resourcequotas",
      "replicationcontrollers",
      "limitranges",
      "persistentvolumeclaims",
      "persistentvolumes",
      "namespaces",
      "endpoints"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "statefulsets",
      "daemonsets",
      "deployments",
      "replicasets"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "cronjobs",
      "jobs"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = [
      "horizontalpodautoscalers"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["authentication.k8s.io"]
    resources = [
      "tokenreviews"
    ]
    verbs = ["create"]
  }

  rule {
    api_groups = ["authorization.k8s.io"]
    resources = [
      "subjectaccessreviews"
    ]
    verbs = ["create"]
  }

  rule {
    api_groups = ["policy"]
    resources = [
      "poddisruptionbudgets"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources = [
      "certificatesigningrequests"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources = [
      "storageclasses",
      "volumeattachments"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources = [
      "mutatingwebhookconfigurations",
      "validatingwebhookconfigurations"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources = [
      "networkpolicies",
      "ingresses"
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources = [
      "leases"
    ]
    verbs = ["list", "watch"]
  }
}

# ClusterRoleBinding for kube-state-metrics
resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kube_state_metrics.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kube_state_metrics.metadata[0].name
    namespace = kubernetes_service_account.kube_state_metrics.metadata[0].namespace
  }
}

# Service for kube-state-metrics
resource "kubernetes_service" "kube_state_metrics" {
  depends_on = [kubernetes_deployment.kube_state_metrics]
  
  metadata {
    name      = "kube-state-metrics"
    namespace = "amazon-cloudwatch"
    labels = {
      app = "kube-state-metrics"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "8080"
    }
  }

  spec {
    selector = {
      app = "kube-state-metrics"
    }

    port {
      name        = "http-metrics"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "telemetry"
      port        = 8081
      target_port = 8081
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Create OpenTelemetry Collector Deployment
resource "kubernetes_deployment" "otel_collector" {
  depends_on = [
    kubernetes_config_map.otel_collector_config,
    kubernetes_service_account.otel_collector,
    kubernetes_cluster_role_binding.otel_collector
  ]
  
  metadata {
    name      = "otel-collector"
    namespace = "amazon-cloudwatch"
    labels = {
      app = "otel-collector"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "otel-collector"
      }
    }

    template {
      metadata {
        labels = {
          app = "otel-collector"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.otel_collector.metadata[0].name
        
        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector-contrib:0.88.0"
          
          args = [
            "--config=/etc/otel-collector-config/config.yaml"
          ]

          port {
            container_port = 8888
            name          = "metrics"
          }

          port {
            container_port = 8889
            name          = "prometheus"
          }

          port {
            container_port = 13133
            name          = "health"
          }

          env {
            name  = "AWS_REGION"
            value = data.aws_region.current.name
          }

          env {
            name  = "CLUSTER_NAME"
            value = aws_eks_cluster.eks.name
          }

          volume_mount {
            name       = "otel-collector-config"
            mount_path = "/etc/otel-collector-config"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 13133
            }
            initial_delay_seconds = 30
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 13133
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }

        volume {
          name = "otel-collector-config"
          config_map {
            name = kubernetes_config_map.otel_collector_config.metadata[0].name
          }
        }
      }
    }
  }
}

########################################################################################################################################################################
########################################################### Outputs ################################################################################################
########################################################################################################################################################################

output "prometheus_workspace_endpoint" {
  description = "Amazon Managed Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.eks_monitoring.prometheus_endpoint
}

output "prometheus_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID"
  value       = aws_prometheus_workspace.eks_monitoring.id
}

output "grafana_workspace_endpoint" {
  description = "Amazon Managed Grafana workspace endpoint"
  value       = aws_grafana_workspace.eks_monitoring.endpoint
}

output "grafana_workspace_id" {
  description = "Amazon Managed Grafana workspace ID"
  value       = aws_grafana_workspace.eks_monitoring.id
}

output "grafana_workspace_url" {
  description = "Amazon Managed Grafana workspace URL"
  value       = "https://${aws_grafana_workspace.eks_monitoring.endpoint}"
}