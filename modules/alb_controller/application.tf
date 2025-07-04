resource "kubernetes_namespace" "customer" {
  metadata {
    name = "customer"
  }
}

resource "kubernetes_ingress_v1" "customer" {
  metadata {
    name      = "alb-ingress-customer-v1"
    namespace = kubernetes_namespace.customer.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "alb"
      "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      "alb.ingress.kubernetes.io/subnets"             = join(",", [data.aws_subnet.public_subnet_az1.id, data.aws_subnet.public_subnet_az2.id])
      "alb.ingress.kubernetes.io/security-groups"     = var.eks_alb_sg_id
      "alb.ingress.kubernetes.io/load-balancer-name"  = "${var.project_name}-alb-customer-${var.env}"
      "alb.ingress.kubernetes.io/tags"                = join(",", [for k, v in var.map_tagging : "${k}=${v}"])
      "alb.ingress.kubernetes.io/certificate-arn"     = var.certificate_arn
      # "alb.ingress.kubernetes.io/listen-ports"        = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/listen-ports"        = "[{\"HTTP\":80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-policy"          = "ELBSecurityPolicy-TLS-1-2-2017-01"
      "alb.ingress.kubernetes.io/ssl-redirect"        = "443"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\":\"redirect\",\"RedirectConfig\":{\"Protocol\":\"HTTPS\",\"Port\":\"443\",\"StatusCode\":\"HTTP_301\"}}"
      "alb.ingress.kubernetes.io/backend-protocol"    = "HTTP"
      # "alb.ingress.kubernetes.io/load-balancer-attributes"= "routing.http.drop_invalid_header_fields.enabled=true"
      
      # Combined load balancer attributes with security headers
     "alb.ingress.kubernetes.io/load-balancer-attributes" = join(",", [
  # Basic Protection
       "deletion_protection.enabled=true",
       "routing.http.drop_invalid_header_fields.enabled=true",
  
  # Security Headers
      # "routing.http.response.strict_transport_security.header_value=max-age=31536000; includeSubdomains",
      # "routing.http.response.x_content_type_options.header_value=nosniff",
      # "routing.http.response.x_frame_options.header_value=SAMEORIGIN",
      # "routing.http.response.referrer_policy.header_value=strict-origin-when-cross-origin",
      # # "routing.http.response.content_security_policy.header_value=default-src 'self'; img-src 'self' data: https:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; connect-src 'self'; font-src 'self' data:; object-src 'none'; media-src 'self'; frame-src 'self'; frame-ancestors 'self'; base-uri 'self'; form-action 'self'",
      # "routing.http.response.content_security_policy.header_value=default-src 'self' https://customerprtlbe.${var.env}.prioritywaste.com",
      # "routing.http.response.permissions_policy.header_value=geolocation=(), camera=(), microphone=(), payment=('self'), fullscreen=('self')",
      # "routing.http.response.x_xss_protection.header_value=0",
      # "routing.http.response.cross_origin_resource_policy.header_value=same-site"

     ])

      
    }
  }


  
  spec {
    ingress_class_name = "alb"  

    rule {
       host = var.customer_domain
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
          path      = "/customer"
          path_type = "Prefix"
          backend {
            service {
              name = "customer-service"
              port {
                number = 8081
              }
            }
          }
        }

        path {
          path      = "/job"
          path_type = "Prefix"
          backend {
            service {
              name = "job-service"
              port {
                number = 8080
              }
            }
          }
        }
        
        path {
          path      = "/payment"
          path_type = "Prefix"
          backend {
            service {
              name = "payment-service"
              port {
                number = 8080
              }
            }
          }
        }
        
        
        path {
        path      = "/"
        path_type = "Prefix"
        backend {
          service {
            name = "upload-service"
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


resource "kubernetes_namespace" "website" {
  metadata {
    name = "website"
  }
}

resource "kubernetes_ingress_v1" "website" {
  metadata {
    name      = "alb-ingress-website-v1"
    namespace = kubernetes_namespace.website.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "alb"
      "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path"    = "/priority/health"
      "alb.ingress.kubernetes.io/subnets"             = join(",", [data.aws_subnet.public_subnet_az1.id, data.aws_subnet.public_subnet_az2.id])
      "alb.ingress.kubernetes.io/security-groups"     = var.eks_alb_sg_id
      "alb.ingress.kubernetes.io/load-balancer-name"  = "${var.project_name}-alb-website-${var.env}"
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
    ingress_class_name = "alb" 

    rule {
       host = var.website_domain
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
          path      = "/priority"
          path_type = "Prefix"
          backend {
            service {
              name = "priority-website-service"
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