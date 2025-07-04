# # Simple way to label default namespace for Istio sidecar injection
# resource "kubernetes_labels" "default_namespace_istio" {
#   api_version = "v1"
#   kind        = "Namespace"
  
#   metadata {
#     name = "default"
#   }
  
#   labels = {
#     "istio-injection" = "enabled"
#   }
  
#   depends_on = [
#     aws_eks_cluster.eks,
#     aws_eks_node_group.frontend-node-grp  # or any one of your node groups
#   ]
# }



# ##########################################################################


# #########################################################################
# # STEP 1: Create Istio System Namespace
# #########################################################################
# resource "kubernetes_namespace" "istio_system" {
#   metadata {
#     name = "istio-system"
#     labels = {
#       name                 = "istio-system"
#       "istio-injection"   = "disabled"
#     }
#   }
  
#   depends_on = [
#     aws_eks_cluster.eks,
#     aws_eks_node_group.istio-node-grp,
#     aws_eks_node_group.backend-node-grp,
#     aws_eks_node_group.frontend-node-grp
#   ]
# }

# #########################################################################
# # STEP 2: Install Istio Base (CRDs and Cluster Roles)
# #########################################################################
# resource "helm_release" "istio_base" {
#   name       = "istio-base"
#   repository = "https://istio-release.storage.googleapis.com/charts"
#   chart      = "base"
#   namespace  = kubernetes_namespace.istio_system.metadata[0].name
# #   version    = var.istio_version # Latest stable, meets OSDU requirement (1.17.2+)
#   version   = "1.21.0"

#   values = [
#     yamlencode({
#       global = {
#         istioNamespace = "istio-system"
        
#         # Allow pods to run on osdu-istio-keycloak nodes
#         defaultTolerations = [
#           {
#             key      = "node-role"
#             operator = "Equal"
#             value    = "osdu-istio-keycloak"
#             effect   = "NoSchedule"
#           }
#         ]
        
#         # Force pods to run ONLY on osdu-istio-keycloak nodes
#         defaultNodeSelector = {
#           "node-role" = "osdu-istio-keycloak"
#         }
#       }
#     })
#   ]

#   depends_on = [kubernetes_namespace.istio_system]
# }

# #########################################################################
# # STEP 3: Install Istio Control Plane (Istiod)
# #########################################################################


# resource "helm_release" "istiod" {
#   name       = "istiod"
#   repository = "https://istio-release.storage.googleapis.com/charts"
#   chart      = "istiod"
#   namespace  = kubernetes_namespace.istio_system.metadata[0].name
#   version    = "1.21.0"

#   values = [
#     yamlencode({
#       # Global configuration for automatic sidecar injection
#       global = {
#         istioNamespace = kubernetes_namespace.istio_system.metadata[0].name
#         proxy = {
#           autoInject = "enabled"
#         }
#       }

#       # Istiod pilot configuration - runs ONLY on Istio nodes
#       pilot = {
#         # Force istiod to run on osdu-istio-keycloak nodes
#         nodeSelector = {
#           "node-role" = "osdu-istio-keycloak"
#         }
        
#         # Allow istiod to tolerate the taint on Istio nodes
#         tolerations = [
#           {
#             key      = "node-role"
#             operator = "Equal"
#             value    = "osdu-istio-keycloak"
#             effect   = "NoSchedule"
#           }
#         ]
#       }

#       # Optional: Telemetry configuration
#       telemetry = {
#         enabled = true
#       }
#     })
#   ]

#   wait    = true
#   timeout = 600

#   depends_on = [
#     helm_release.istio_base,  # Assuming you have istio-base installed first
#     kubernetes_namespace.istio_system,
#     aws_eks_node_group.istio-node-grp  # Ensure Istio nodes are ready
#   ]
# }


# #########################################################################
# # STEP 4: Install Istio Ingress Gateway (FIXED VERSION)
# #########################################################################

# resource "kubernetes_namespace" "istio_gateway" {
#   metadata {
#     name = "istio-gateway"
#     labels = {
#       istio-injection = "enabled"
#     }
#   }

#   depends_on = [aws_eks_node_group.istio-node-grp,
#     aws_eks_node_group.backend-node-grp,
#     aws_eks_node_group.frontend-node-grp]
# }


# resource "helm_release" "istio_ingress" {
#   name             = "istio-ingress"
#   repository       = "https://istio-release.storage.googleapis.com/charts"
#   chart            = "gateway"
#   namespace        = kubernetes_namespace.istio_gateway.metadata.0.name
#   version          = "1.21.0"
#   timeout          = 500
#   force_update     = true
#   recreate_pods    = true
#   description      = "force update 1"

#   values = [
#     yamlencode({
#       # Gateway image configuration
#       image = {
#         repository = "docker.io/istio/proxyv2"
#         tag        = "1.21.0"
#         pullPolicy = "IfNotPresent"
#       }

#       # LoadBalancer service configuration
#       service = {
#         type = "LoadBalancer"
#         ports = [
#           {
#             port       = 80
#             targetPort = 8080
#             name       = "http2"
#           },
#           {
#             port       = 443
#             targetPort = 8443
#             name       = "https"
#           }
#         ]
#         externalTrafficPolicy = "Local"
#       }

#       # Gateway labels
#       labels = {
#         istio = "ingressgateway"
#       }

#       # Force gateway to run ONLY on osdu-istio-keycloak nodes
#       nodeSelector = {
#         "node-role" = "osdu-istio-keycloak"
#       }

#       # Allow gateway to ignore the taint on osdu-istio-keycloak nodes
#       tolerations = [
#         {
#           key      = "node-role"
#           operator = "Equal"
#           value    = "osdu-istio-keycloak"
#           effect   = "NoSchedule"
#         }
#       ]
#     })
#   ]

#   wait = true
#   # timeout = 600

#   depends_on = [
#     helm_release.istio_base,
#     helm_release.istiod,
#   ]
# }





############################################################################################################################################


# Complete Istio and OSDU Installation Configuration
# This file includes proper dependency ordering to prevent CRD errors

#########################################################################
# STEP 1: Label Default Namespace for Istio Sidecar Injection
#########################################################################
resource "kubernetes_labels" "default_namespace_istio" {
  api_version = "v1"
  kind        = "Namespace"
  
  metadata {
    name = "default"
  }
  
  labels = {
    "istio-injection" = "enabled"
  }
  
  depends_on = [
    aws_eks_cluster.eks,
    # aws_eks_node_group.frontend-node-grp
  ]
}

#########################################################################
# STEP 2: Create Istio System Namespace
#########################################################################
# resource "kubernetes_namespace" "istio_system" {
#   metadata {
#     name = "istio-system"
#     labels = {
#       name                 = "istio-system"
#       "istio-injection"   = "disabled"
#     }
#   }

  resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }

  
  depends_on = [
    aws_eks_cluster.eks
    # aws_eks_node_group.istio-node-grp,
    # aws_eks_node_group.backend-node-grp,
    # aws_eks_node_group.frontend-node-grp
  ]
}

#########################################################################
# STEP 3: Install Istio Base (CRDs and Cluster Roles)
#########################################################################
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.21.0"

  values = [
    yamlencode({
      global = {
        istioNamespace = "istio-system"
        
        # Allow pods to run on osdu-istio-keycloak nodes
        defaultTolerations = [
          {
            key      = "node-role"
            operator = "Equal"
            value    = "osdu-istio-keycloak"
            effect   = "NoSchedule"
          }
        ]
        
        # Force pods to run ONLY on osdu-istio-keycloak nodes
        defaultNodeSelector = {
          "node-role" = "osdu-istio-keycloak"
        }
      }
    })
  ]

  wait              = true
  timeout           = 300
  dependency_update = true

  depends_on = [kubernetes_namespace.istio_system]
}

#########################################################################
# STEP 4: Install Istio Control Plane (Istiod)
#########################################################################
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.21.0"

  values = [
    yamlencode({
      # Global configuration for automatic sidecar injection
      global = {
        istioNamespace = kubernetes_namespace.istio_system.metadata[0].name
        proxy = {
          autoInject = "enabled"
        }
      }

      # Istiod pilot configuration - runs ONLY on Istio nodes
      pilot = {
        # Force istiod to run on osdu-istio-keycloak nodes
        nodeSelector = {
          "node-role" = "osdu-istio-keycloak"
        }
        
        # Allow istiod to tolerate the taint on Istio nodes
        tolerations = [
          {
            key      = "node-role"
            operator = "Equal"
            value    = "osdu-istio-keycloak"
            effect   = "NoSchedule"
          }
        ]

        # Resource limits for pilot
        resources = {
          requests = {
            cpu    = "500m"
            memory = "2048Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "4096Mi"
          }
        }
      }

      # Optional: Telemetry configuration
      telemetry = {
        enabled = true
      }
    })
  ]

  wait              = true
  timeout           = 600
  dependency_update = true

  depends_on = [
    helm_release.istio_base,
    kubernetes_namespace.istio_system
    # aws_eks_node_group.istio-node-grp
  ]
}

#########################################################################
# STEP 5: Create Istio Gateway Namespace
#########################################################################
resource "kubernetes_namespace" "istio_gateway" {
  metadata {
    name = "istio-gateway"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [
    helm_release.istiod
    # aws_eks_node_group.istio-node-grp,
    # aws_eks_node_group.backend-node-grp,
    # aws_eks_node_group.frontend-node-grp
  ]
}

#########################################################################
# STEP 6: Install Istio Ingress Gateway
#########################################################################
resource "helm_release" "istio_ingressgateway" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_gateway.metadata[0].name
  version    = "1.21.0"
  timeout    = 500
  
#   # Helm release management options
#   force_update     = true
#   recreate_pods    = true
#   replace          = true
#   reset_values     = false
#   reuse_values     = true
  
#   # Lifecycle management
#   lifecycle {
#     ignore_changes = [description]
#   }

  values = [
    yamlencode({
      # Gateway image configuration
      image = {
        repository = "docker.io/istio/proxyv2"
        tag        = "1.21.0"
        pullPolicy = "IfNotPresent"
      }

      # LoadBalancer service configuration
      service = {
        type = "LoadBalancer"
        ports = [
          {
            port       = 80
            targetPort = 8080
            name       = "http2"
          },
          {
            port       = 443
            targetPort = 8443
            name       = "https"
          }
        ]
        externalTrafficPolicy = "Local"
        
        # # Optional: Add annotations for AWS Load Balancer
        # annotations = {
        #   "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        #   "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
        # }
      }

    #   # Gateway labels
    #   labels = {
    #     istio = "ingressgateway"
    #   }

      # Force gateway to run ONLY on osdu-istio-keycloak nodes
      nodeSelector = {
        "node-role" = "osdu-istio-keycloak"
      }

      # Allow gateway to ignore the taint on osdu-istio-keycloak nodes
      tolerations = [
        {
          key      = "node-role"
          operator = "Equal"
          value    = "osdu-istio-keycloak"
          effect   = "NoSchedule"
        }
      ]

      # Resource configuration
    #   resources = {
    #     requests = {
    #       cpu    = "100m"
    #       memory = "128Mi"
    #     }
    #     limits = {
    #       cpu    = "500m"
    #       memory = "512Mi"
    #     }
    #   }

    #   # Pod disruption budget
    #   podDisruptionBudget = {
    #     enabled        = true
    #     minAvailable   = 1
    #     maxUnavailable = null
    #   }

    #   # Autoscaling
    #   autoscaling = {
    #     enabled   = false
    #     minReplicas = 1
    #     maxReplicas = 3
    #   }
    })
  ]

#   wait              = true
#   wait_for_jobs     = true
#   dependency_update = true

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod,
    kubernetes_namespace.istio_gateway
  ]
}

#########################################################################
# STEP 7: Wait for Istio to be Fully Ready
#########################################################################
resource "null_resource" "wait_for_istio_ready" {
  depends_on = [helm_release.istio_ingressgateway]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Istio components to be ready..."
      
      # Wait for istiod to be ready
      kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s || echo "Warning: istiod pods not ready"
      
      # Wait for ingress gateway to be ready
      kubectl wait --for=condition=ready pod -l istio=ingressgateway -n istio-gateway --timeout=300s || echo "Warning: ingress gateway pods not ready"
      
      # Verify CRDs are installed
      kubectl get crd gateways.networking.istio.io || echo "Warning: Gateway CRD not found"
      kubectl get crd virtualservices.networking.istio.io || echo "Warning: VirtualService CRD not found"
      kubectl get crd authorizationpolicies.security.istio.io || echo "Warning: AuthorizationPolicy CRD not found"
      
      echo "Istio readiness check completed!"
    EOT
  }

  triggers = {
    istio_base_version = helm_release.istio_base.version
    istiod_version     = helm_release.istiod.version
    gateway_version    = helm_release.istio_ingressgateway.version
  }
}

#########################################################################
# STEP 8: Get Istio Gateway Service Information
#########################################################################
data "kubernetes_service" "istio_gateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = kubernetes_namespace.istio_gateway.metadata[0].name
  }
  
  depends_on = [
    null_resource.wait_for_istio_ready,
    helm_release.istio_ingressgateway
  ]
}

#########################################################################
# STEP 9: Local Values for Gateway Domain
#########################################################################
locals {
  istio_gateway_domain = try(
    data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname,
    data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].ip,
    "localhost"  # fallback for testing
  )
}