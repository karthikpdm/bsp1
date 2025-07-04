

# # terraform {
# #   required_providers {
# #     aws = {
# #       source  = "hashicorp/aws"
# #       version = "5.98.0"
# #     }

# #     helm = {
# #       source  = "hashicorp/helm"
# #       version = ">= 2.11.0"
# #     }

# #     kubernetes = {
# #       source  = "hashicorp/kubernetes"
# #       version = "~> 2.37"
# #     }

# #     tls = {
# #       source  = "hashicorp/tls"
# #       version = "~> 4.1"
# #     }

# #     null = {
# #       source  = "hashicorp/null"
# #       version = "~> 3.2"
# #     }
# #   }
# # }

# provider "aws" {
#   region = var.region
# }



# # provider "aws" {
# #   region = var.aws_region

# #   assume_role {
# #     role_arn = var.assume_role_arn
# #   }
# # }

# # terraform {
# #   required_providers {
# #     aws = {
# #       source  = "hashicorp/aws"
# #       version = "~> 5.0"
# #     }
# #     kubernetes = {
# #       source  = "hashicorp/kubernetes"
# #       version = "~> 2.0"
# #     }
# #     helm = {
# #       source  = "hashicorp/helm"
# #       version = "~> 2.0"
# #     }
# #   }
# # }


# # providers.tf - Add this file to your monitoring module directory

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.0"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 2.0"
#     }
#   }
# }

# # Data source to get current AWS caller identity
# # data "aws_caller_identity" "current" {}

# # # Configure Kubernetes provider to connect to your EKS cluster
# # provider "kubernetes" {
# #   host                   = var.cluster_endpoint
# #   cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  
# #   exec {
# #     api_version = "client.authentication.k8s.io/v1beta1"
# #     command     = "aws"
# #     args = [
# #       "eks",
# #       "get-token",
# #       "--cluster-name",
# #       var.eks_cluster_name,
# #       "--region",
# #       var.aws_region
# #     ]
# #   }
# # }

# # # Configure Helm provider to deploy charts to your EKS cluster
# # provider "helm" {
# #   kubernetes {
# #     host                   = var.cluster_endpoint
# #     cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    
# #     exec {
# #       api_version = "client.authentication.k8s.io/v1beta1"
# #       command     = "aws"
# #       args = [
# #         "eks",
# #         "get-token",
# #         "--cluster-name",
# #         var.eks_cluster_name,
# #         "--region",
# #         var.aws_region
# #       ]
# #     }
# #   }
# # }