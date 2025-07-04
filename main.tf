# main.tf

module "iam" {
  source = "./modules/iam"

  project_name                  = var.project_name
  env                           = var.env
  eks_oidc_provider_arn         = module.eks.oidc_provider_arn
  eks_oidc_provider_url         = module.eks.oidc_provider_url
  map_tagging                   = var.map_tagging
    
  
}

module "security_groups" {
  source = "./modules/sg"

  project_name          = var.project_name
  env                   = var.env
  master_ingress_rules  = var.master_ingress_rules
  master_egress_rules   = var.master_egress_rules
  map_tagging           = var.map_tagging
  workers_ingress_rules = var.workers_ingress_rules
  workers_egress_rules  = var.workers_egress_rules
  
  # eks_workers_sg_id     = var.eks_workers_sg_id
}

module "eks" {
  source = "./modules/eks"

  project_name                  = var.project_name
  env                           = var.env
  eks_version                   = var.eks_version
  master_role_arn               = module.iam.master_role_arn
  worker_role_arn               = module.iam.worker_role_arn
  # desired_size                  = var.desired_size
  # max_size                      = var.max_size
  # min_size                      = var.min_size
  # disk_size                     = var.disk_size
  # max_unavailable               = var.max_unavailable
  # instance_type                 = var.instance_type
  eks_master_sg_id              = module.security_groups.eks_master_sg_id
  region                        = var.region
  map_tagging                   = var.map_tagging
  # ami_type                      = var.ami_type
  
  # karpenter_version             = var.karpenter_version
  # karpenter_vcpu                = var.karpenter_vcpu
  # karpenter_memory              = var.karpenter_memory
  
  
  # customer_namespace_name       = module.alb_controller.customer_namespace_name
  # website_namespace_name        = module.alb_controller.website_namespace_name
  # internal_namespace_name       = module.alb_controller.internal_namespace_name
  
  account_id = var.account_id
  ebs_csi_driver_role_arn         = module.iam.ebs_csi_driver_role_arn
  
  
  metrics_server_version        = var.metrics_server_version
}


# In your main.tf file

# Configure providers at the root level
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Data source to get current region
data "aws_region" "current" {}

# # EKS module (existing)
# module "eks" {
#   source = "./modules/eks"
#   # ... your EKS module variables
# }

# Configure Kubernetes provider AFTER EKS cluster is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", data.aws_region.current.name]
  }
}

# Configure Helm provider AFTER EKS cluster is created
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", data.aws_region.current.name]
    }
  }
}

# Monitoring module - will use the providers configured above
module "monitoring" {
  source = "./modules/monitorings"
  
  eks_cluster_name         = module.eks.cluster_name
  eks_cluster_oidc_issuer  = module.eks.eks_cluster_oidc_issuer
  oidc_provider_arn        = module.eks.oidc_provider_arn
  aws_region               = data.aws_region.current.name
  # cluster_endpoint       = module.eks.cluster_endpoint
  # cluster_ca_certificate = module.eks.cluster_ca_certificate
  
  # Ensure monitoring runs after EKS is ready
  # depends_on = [module.eks]
}

# module "monitoring" {
#   source = "./modules/monitorings"
  
#   # Pass EKS module outputs
#   # cluster_name           = module.eks.cluster_name
#   # cluster_endpoint       = module.eks.cluster_endpoint
#   # cluster_ca_certificate = module.eks.cluster_ca_certificate
#   # oidc_issuer_url       = module.eks.eks_cluster_oidc_issuer
#   # oidc_provider_arn     = module.eks.oidc_provider_arn

#   # Use outputs from your EKS module
#   eks_cluster_name         = module.eks.cluster_name
#   eks_cluster_oidc_issuer  = module.eks.eks_cluster_oidc_issuer
#   oidc_provider_arn        = module.eks.oidc_provider_arn
#   aws_region               = "us-east-1"

#   # NEW variables for Kubernetes/Helm providers
#   cluster_endpoint         = module.eks.cluster_endpoint
#   cluster_ca_certificate   = module.eks.cluster_ca_certificate

#     # Pass the providers from EKS module
#   # providers = {
#   #   # aws        = aws
#   #   kubernetes = kubernetes
#   #   helm       = helm
#   # }
  
#   # Environment variable for naming convention
#   # environment = "poc"  # or "dev", "staging", etc.
  
#   # depends_on = [module.eks]
# }


# module "alb_controller" {
#   source = "./modules/alb_controller"
  
#   project_name            = "pw"
#   env                     = var.env
#   cluster_name            = module.eks.cluster_name
#   cluster_endpoint        = module.eks.cluster_endpoint
#   cluster_ca_certificate  = module.eks.cluster_ca_certificate
#   oidc_provider_arn       = module.eks.oidc_provider_arn
#   aws_region              = var.aws_region
#   alb_controller_role_arn = module.iam.alb_controller_role_arn
#   eks_alb_sg_id           = module.security_groups.eks_alb_ingress_sg_id
#   map_tagging             = var.map_tagging
#   certificate_arn        = var.certificate_arn
#   customer_domain        = var.customer_domain
#   website_domain        = var.website_domain
#   internal_domain        = var.internal_domain
#   eks_websocket_alb_sg_id = module.security_groups.eks_alb_ingress_websocket_sg_id
# }

# module "waf" {
#   source = "./modules/waf"

#   project_name          = "pw"
#   env                   = var.env
#   map_tagging           = var.map_tagging
# }

# module "monitoring" {
#   source = "./modules/monitoring"

#   project_name                  = "pw"
#   env                           = var.env
#   map_tagging                   = var.map_tagging
#   email_subscribers             = var.email_subscribers
# }