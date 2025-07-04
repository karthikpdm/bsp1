################################################################################################

# Data sources for existing VPC components
data "aws_vpc" "pw_vpc" {
  filter {
    name   = "tag:Name"
    values = ["pw-vpc-${var.env}"]
  }
}

data "aws_eks_cluster_auth" "pw_eks" {
  name = var.cluster_name
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

#####################################################################################

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.pw_eks.token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.pw_eks.token
  }
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.pw_vpc.id
  }

  # depends_on = [kubernetes_service_account.aws_load_balancer_controller]
}

# ################################ internal ingress resources  ####################################

resource "kubernetes_namespace" "internal" {
  metadata {
    name = "internal"
  }
}

resource "kubernetes_ingress_v1" "internal" {
  metadata {
    name      = "alb-ingress-internal-v1"
    namespace = kubernetes_namespace.internal.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "alb"
      "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      
      "alb.ingress.kubernetes.io/subnets"             = join(",", [data.aws_subnet.public_subnet_az1.id, data.aws_subnet.public_subnet_az2.id])
      "alb.ingress.kubernetes.io/load-balancer-name"  = "${var.project_name}-alb-internal-${var.env}"
      "alb.ingress.kubernetes.io/tags"                = join(",", [for k, v in var.map_tagging : "${k}=${v}"])
      "alb.ingress.kubernetes.io/certificate-arn"     = var.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"        = "[{\"HTTP\":80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-policy"          = "ELBSecurityPolicy-TLS-1-2-2017-01"
      "alb.ingress.kubernetes.io/ssl-redirect"        = "443"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\":\"redirect\",\"RedirectConfig\":{\"Protocol\":\"HTTPS\",\"Port\":\"443\",\"StatusCode\":\"HTTP_301\"}}"
      "alb.ingress.kubernetes.io/backend-protocol"    = "HTTP"
      
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "deletion_protection.enabled=true,routing.http.drop_invalid_header_fields.enabled=true"
      
    }
  }
  spec {
    ingress_class_name = "alb"  # Replace with your ingress class

    rule {
      host = var.internal_domain
      http {


        path {
          path      = "/ssl-redirect"
          path_type = "Prefix"
          backend {
            service {
              name = "ssl-redirect"
              port {
                name = "use-annotation"
              }
            }
          }
        }
        

        path {
          path      = "/vehicle/"
          path_type = "Prefix"
          backend {
            service {
              name = "fleet-vehicle-service"
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path      = "/scheduler/"
          path_type = "Prefix"
          backend {
            service {
              name = "scheduler-dispatcher-service"
              port {
                number = 8080
              }
            }
          }
        }
        
        path {
          path      = "/driver/"
          path_type = "Prefix"
          backend {
            service {
              name = "portal-driver-service"
              port {
                number = 8080
              }
            }
          }
        }
        path {
        path      = "/ftdriver/"
        path_type = "Prefix"
        backend {
          service {
            name = "fleet-driver-service"
            port {
              number = 8081
            }
          }
        }
      }
        path {
        path      = "/s3Service/"
        path_type = "Prefix"
        backend {
          service {
            name = "internal-upload-service"
            port {
              number = 8080
            }
          }
        }
      }
       
      #  path {
      #   path      = "/integration/"
      #   path_type = "Prefix"
      #   backend {
      #     service {
      #       name = "backend-integration-service"
      #       port {
      #         number = 8080
      #       }
      #     }
      #   }
      # }

      }
    }
  }
}





# ################################ internal ingress for websocket  ####################################



resource "kubernetes_ingress_v1" "internal-websocket" {
  metadata {
    name      = "alb-ingress-internal-websocket-v1"
    namespace = kubernetes_namespace.internal.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "alb"
      "alb.ingress.kubernetes.io/scheme"              = "internal"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      "alb.ingress.kubernetes.io/subnets"             = join(",", [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id])
      "alb.ingress.kubernetes.io/security-groups"     = var.eks_websocket_alb_sg_id
      "alb.ingress.kubernetes.io/load-balancer-name"  = "${var.project_name}-alb-internal-websocket-${var.env}"
      "alb.ingress.kubernetes.io/tags"                = join(",", [for k, v in var.map_tagging : "${k}=${v}"])
      "alb.ingress.kubernetes.io/security-groups"     = var.eks_alb_sg_id
      "alb.ingress.kubernetes.io/backend-protocol"    = "HTTP"
      
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "deletion_protection.enabled=true,routing.http.drop_invalid_header_fields.enabled=true"
      
    }
  }
  spec {
    ingress_class_name = "alb"  # Replace with your ingress class

    rule {
      # host = var.internal_domain
      http {


        

        path {
          path      = "/scheduler/"
          path_type = "Prefix"
          backend {
            service {
              name = "scheduler-dispatcher-service"
              port {
                number = 8080
              }
            }
          }
        }
        
       
      }
    }
  }
}

