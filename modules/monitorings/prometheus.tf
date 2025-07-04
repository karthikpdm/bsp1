# # modules/"monitoring"/variables.tf
# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
# }

# variable "cluster_endpoint" {
#   description = "EKS cluster endpoint"
#   type        = string
# }

# variable "cluster_ca_certificate" {
#   description = "EKS cluster certificate authority data"
#   type        = string
# }

# variable "oidc_issuer_url" {
#   description = "OIDC issuer URL for the EKS cluster"
#   type        = string
# }

# variable "oidc_provider_arn" {
#   description = "ARN of the OIDC provider"
#   type        = string
# }

# variable "environment" {
#   description = "Environment name (e.g., dev, staging, prod)"
#   type        = string
#   default     = "prod"
# }

# # modules/"monitoring"/prometheus.tf
# # This file contains essential AWS Managed Prometheus components for EKS "monitoring"

# # =============================================================================
# # DATA SOURCES
# # =============================================================================

# # Data source to get current AWS region
# data "aws_region" "current" {}

# # Data source to get current AWS caller identity
# data "aws_caller_identity" "current" {}

# # Data source to get EKS cluster authentication
# # This provides the token needed to authenticate with the EKS cluster
# data "aws_eks_cluster_auth" "main" {
#   name = var.cluster_name
# }



# # Configure Kubernetes provider to connect to EKS cluster
# # This uses the outputs from your EKS module to establish connection
# provider "kubernetes" {
#   host                   = var.cluster_endpoint
#   cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
#   token                  = data.aws_eks_cluster_auth.main.token
# }

# # =============================================================================
# # AWS MANAGED PROMETHEUS WORKSPACE
# # =============================================================================

# # AWS Managed Prometheus Workspace
# # This creates a managed Prometheus workspace that will store and query metrics
# # from your EKS cluster. Benefits:
# # - Fully managed service that handles scaling, availability, and security
# # - Automatically scales based on ingestion and query load
# # - Integrates with AWS IAM for authentication and authorization
# # - Supports long-term storage with automatic data lifecycle management
# # - Compatible with Prometheus APIs and PromQL queries
# resource "aws_prometheus_workspace" "main" {
#   alias = "bsp-prometheus-${var.environment}"
  
#   tags = {
#     Name        = "bsp-prometheus-${var.environment}"
#     Environment = var.environment
#     Purpose     = "EKS-"monitoring""
#     Team        = "DevOps"
#     ClusterName = var.cluster_name
#   }
# }

# # =============================================================================
# # IAM ROLES AND POLICIES FOR PROMETHEUS
# # =============================================================================

# # IAM Role for Prometheus Service
# # This role allows AWS Managed Prometheus service to access necessary AWS services
# # The assume role policy allows the prometheus.amazonaws.com service to assume this role
# # resource "aws_iam_role" "prometheus_role" {
# #   name = "bsp-prometheus-service-${var.environment}"

# #   assume_role_policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Action = "sts:AssumeRole"
# #         Effect = "Allow"
# #         Principal = {
# #           Service = "prometheus.amazonaws.com"
# #         }
# #       }
# #     ]
# #   })

# #   tags = {
# #     Name        = "bsp-prometheus-service-${var.environment}"
# #     Environment = var.environment
# #     Purpose     = "prometheus-service"
# #   }
# # }

# # # IAM Policy for Prometheus to access metrics and perform queries
# # # This policy defines what actions Prometheus can perform on the workspace
# # resource "aws_iam_policy" "prometheus_policy" {
# #   name        = "bsp-prometheus-access-${var.environment}"
# #   description = "Policy for AWS Managed Prometheus to access metrics and perform queries"

# #   policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Effect = "Allow"
# #         Action = [
# #           "aps:RemoteWrite",        # Allow writing metrics to AMP
# #           "aps:QueryMetrics",       # Allow querying metrics from AMP
# #           "aps:GetSeries",          # Allow getting time series data
# #           "aps:GetLabels",          # Allow getting metric labels
# #           "aps:GetMetricMetadata",  # Allow getting metadata about metrics
# #           "aps:ListRules",          # Allow listing alerting rules
# #           "aps:ListRuleGroupsNamespaces", # Allow listing rule group namespaces
# #           "aps:DescribeRuleGroupsNamespace", # Allow describing rule groups
# #           "aps:PutRuleGroupsNamespace", # Allow creating/updating rule groups
# #           "aps:DeleteRuleGroupsNamespace" # Allow deleting rule groups
# #         ]
# #         Resource = aws_prometheus_workspace.main.arn
# #       }
# #     ]
# #   })
# # }

# # # Attach the policy to the Prometheus service role
# # resource "aws_iam_role_policy_attachment" "prometheus_policy_attachment" {
# #   role       = aws_iam_role.prometheus_role.name
# #   policy_arn = aws_iam_policy.prometheus_policy.arn
# # }

# # =============================================================================
# # EKS INTEGRATION - IRSA (IAM Roles for Service Accounts)
# # =============================================================================

# # IAM Role for Prometheus running in EKS
# # This role uses IRSA (IAM Roles for Service Accounts) to allow Prometheus pods
# # running in EKS to authenticate with AWS and write metrics to AMP
# # IRSA eliminates the need to store AWS credentials in pods
# resource "aws_iam_role" "prometheus_eks_role" {
#   name = "bsp-prometheus-eks-${var.environment}"

#   # The assume role policy allows the EKS service account to assume this role
#   # The condition ensures only the specific service account can assume this role
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           # Uses the OIDC provider ARN from your EKS module
#           Federated = var.oidc_provider_arn
#         }
#         Condition = {
#           StringEquals = {
#             # These conditions ensure only the prometheus service account in "monitoring" namespace can assume this role
#             "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:"monitoring":bsp-prometheus-${var.environment}"
#             "${replace(var.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     Name        = "bsp-prometheus-eks-${var.environment}"
#     Environment = var.environment
#     Purpose     = "prometheus-eks-irsa"
#     ClusterName = var.cluster_name
#   }
# }

# # Attach AWS managed policy for Prometheus remote write access
# # This policy allows the EKS-based Prometheus to write metrics to AMP
# resource "aws_iam_role_policy_attachment" "prometheus_eks_remote_write" {
#   role       = aws_iam_role.prometheus_eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
# }

# # Additional policy for Prometheus to query AMP
# # This allows Prometheus to read metrics back from AMP for local queries
# resource "aws_iam_policy" "prometheus_eks_query_policy" {
#   name        = "bsp-prometheus-query-${var.environment}"
#   description = "Policy for Prometheus running in EKS to query AMP"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "aps:QueryMetrics",       # Allow querying metrics from AMP
#           "aps:GetSeries",          # Allow getting time series data
#           "aps:GetLabels",          # Allow getting metric labels
#           "aps:GetMetricMetadata"   # Allow getting metadata about metrics
#         ]
#         Resource = aws_prometheus_workspace.main.arn
#       }
#     ]
#   })
# }

# # Attach the query policy to the EKS role
# resource "aws_iam_role_policy_attachment" "prometheus_eks_query_policy_attachment" {
#   role       = aws_iam_role.prometheus_eks_role.name
#   policy_arn = aws_iam_policy.prometheus_eks_query_policy.arn
# }

# # =============================================================================
# # KUBERNETES RESOURCES FOR PROMETHEUS
# # =============================================================================

# # Create "monitoring" namespace
# # This namespace will contain all "monitoring" components including Prometheus
# # resource "kubernetes_namespace" ""monitoring"" {
# #   metadata {
# #     name = ""monitoring""
# #     labels = {
# #       name = ""monitoring""
# #       purpose = "observability"
# #       environment = var.environment
# #     }
# #   }
# # }

# # Service account for Prometheus with IRSA annotation
# # This service account is linked to the AWS IAM role through the annotation
# # This allows Prometheus pods to authenticate with AWS without storing credentials
# resource "kubernetes_service_account" "prometheus" {
#   metadata {
#     name      = "bsp-prometheus-${var.environment}"
#     namespace = ""monitoring""
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_eks_role.arn
#     }
#     labels = {
#       app = "bsp-prometheus-${var.environment}"
#       environment = var.environment
#     }
#   }
# }

# # ConfigMap for Prometheus configuration
# # This contains the prometheus.yml configuration file that defines:
# # - How often to scrape metrics (scrape_interval)
# # - What targets to scrape (scrape_configs)
# # - How to send metrics to AWS Managed Prometheus (remote_write)
# resource "kubernetes_config_map" "prometheus_config" {
#   metadata {
#     name      = "bsp-prometheus-config-${var.environment}"
#     namespace = ""monitoring""
#     labels = {
#       app = "bsp-prometheus-${var.environment}"
#       environment = var.environment
#     }
#   }

#   data = {
#     "prometheus.yml" = <<-EOT
#       # Global configuration
#       global:
#         scrape_interval: 15s      # How often to scrape targets
#         evaluation_interval: 15s  # How often to evaluate rules
#         external_labels:
#           cluster: ${var.cluster_name}
#           region: ${data.aws_region.current.name}
#           environment: ${var.environment}

#       # Remote write configuration for AWS Managed Prometheus
#       # This sends all collected metrics to your AMP workspace
#       remote_write:
#         - url: https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.main.id}/api/v1/remote_write
#           queue_config:
#             max_samples_per_send: 1000  # Maximum samples per send
#             max_shards: 200             # Maximum parallel shards
#             capacity: 2500              # Queue capacity
#           sigv4:
#             region: ${data.aws_region.current.name}

#       # Comprehensive scrape configurations for EKS "monitoring"
#       scrape_configs:
        
#         # Scrape Prometheus itself for self-"monitoring"
#         - job_name: 'prometheus'
#           static_configs:
#             - targets: ['localhost:9090']
#           scrape_interval: 15s
#           metrics_path: /metrics

#         # Scrape Kubernetes API server metrics
#         # This provides cluster-level metrics about API server performance
#         - job_name: 'kubernetes-apiservers'
#           kubernetes_sd_configs:
#             - role: endpoints
#               namespaces:
#                 names:
#                   - default
#           scheme: https
#           tls_config:
#             ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
#             insecure_skip_verify: true
#           bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
#           relabel_configs:
#             - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
#               action: keep
#               regex: default;kubernetes;https
#             - target_label: __address__
#               replacement: kubernetes.default.svc:443

#         # Scrape Kubernetes nodes metrics
#         # This provides node-level metrics like CPU, memory, disk usage
#         - job_name: 'kubernetes-nodes'
#           kubernetes_sd_configs:
#             - role: node
#           scheme: https
#           tls_config:
#             ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
#             insecure_skip_verify: true
#           bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
#           relabel_configs:
#             - action: labelmap
#               regex: __meta_kubernetes_node_label_(.+)
#             - target_label: __address__
#               replacement: kubernetes.default.svc:443
#             - source_labels: [__meta_kubernetes_node_name]
#               regex: (.+)
#               target_label: __metrics_path__
#               replacement: /api/v1/nodes/$1/proxy/metrics

#         # Scrape Kubernetes cAdvisor metrics (container metrics)
#         # This provides detailed container-level metrics
#         - job_name: 'kubernetes-cadvisor'
#           kubernetes_sd_configs:
#             - role: node
#           scheme: https
#           tls_config:
#             ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
#             insecure_skip_verify: true
#           bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
#           relabel_configs:
#             - action: labelmap
#               regex: __meta_kubernetes_node_label_(.+)
#             - target_label: __address__
#               replacement: kubernetes.default.svc:443
#             - source_labels: [__meta_kubernetes_node_name]
#               regex: (.+)
#               target_label: __metrics_path__
#               replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor

#         # Scrape Node Exporter metrics (node-level metrics)
#         # This provides detailed host-level metrics like disk, network, filesystem
#         - job_name: 'node-exporter'
#           kubernetes_sd_configs:
#             - role: endpoints
#           relabel_configs:
#             - source_labels: [__meta_kubernetes_endpoints_name]
#               regex: 'node-exporter'
#               action: keep
#             - source_labels: [__meta_kubernetes_endpoint_port_name]
#               regex: 'metrics'
#               action: keep
#             - source_labels: [__meta_kubernetes_endpoint_address_target_name]
#               target_label: instance
#             - action: labelmap
#               regex: __meta_kubernetes_service_label_(.+)

#         # Scrape kube-state-metrics (Kubernetes object state metrics)
#         # This provides metrics about Kubernetes objects like deployments, pods, services
#         - job_name: 'kube-state-metrics'
#           kubernetes_sd_configs:
#             - role: endpoints
#           relabel_configs:
#             - source_labels: [__meta_kubernetes_service_name]
#               regex: kube-state-metrics
#               action: keep
#             - source_labels: [__meta_kubernetes_endpoint_port_name]
#               regex: http-metrics
#               action: keep

#         # Scrape Kubernetes pods with prometheus.io/scrape annotation
#         # This allows applications to expose their own metrics
#         - job_name: 'kubernetes-pods'
#           kubernetes_sd_configs:
#             - role: pod
#           relabel_configs:
#             - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
#               action: keep
#               regex: true
#             - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
#               action: replace
#               target_label: __scheme__
#               regex: (https?)
#             - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
#               action: replace
#               target_label: __metrics_path__
#               regex: (.+)
#             - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
#               action: replace
#               regex: ([^:]+)(?::\d+)?;(\d+)
#               replacement: $1:$2
#               target_label: __address__
#             - action: labelmap
#               regex: __meta_kubernetes_pod_label_(.+)
#             - source_labels: [__meta_kubernetes_namespace]
#               action: replace
#               target_label: kubernetes_namespace
#             - source_labels: [__meta_kubernetes_pod_name]
#               action: replace
#               target_label: kubernetes_pod_name

#         # Scrape Kubernetes services with prometheus.io/scrape annotation
#         # This provides metrics from services that expose metrics endpoints
#         - job_name: 'kubernetes-services'
#           kubernetes_sd_configs:
#             - role: service
#           metrics_path: /probe
#           params:
#             module: [http_2xx]
#           relabel_configs:
#             - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
#               action: keep
#               regex: true
#             - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
#               action: replace
#               target_label: __scheme__
#               regex: (https?)
#             - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
#               action: replace
#               target_label: __metrics_path__
#               regex: (.+)
#             - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
#               action: replace
#               target_label: __address__
#               regex: ([^:]+)(?::\d+)?;(\d+)
#               replacement: $1:$2
#     EOT
#   }
# }

# # =============================================================================
# # PROMETHEUS DEPLOYMENT
# # =============================================================================

# # Prometheus deployment
# # This runs the Prometheus server in the EKS cluster
# # Prometheus will scrape metrics from various sources and send them to AMP
# resource "kubernetes_deployment" "prometheus" {
#   metadata {
#     name      = "bsp-prometheus-${var.environment}"
#     namespace = ""monitoring""
#     labels = {
#       app = "bsp-prometheus-${var.environment}"
#       environment = var.environment
#     }
#   }

#   spec {
#     replicas = 1  # Single replica for basic setup, can be scaled for HA

#     selector {
#       match_labels = {
#         app = "bsp-prometheus-${var.environment}"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "bsp-prometheus-${var.environment}"
#           environment = var.environment
#         }
#         annotations = {
#           "prometheus.io/scrape" = "true"
#           "prometheus.io/port"   = "9090"
#           "prometheus.io/path"   = "/metrics"
#         }
#       }

#       spec {
#         # Use the service account with IRSA configuration
#         service_account_name = kubernetes_service_account.prometheus.metadata[0].name

#         container {
#           name  = "prometheus"
#           image = "prom/prometheus:v2.45.0"

#           port {
#             container_port = 9090
#             name          = "web"
#           }

#           # Prometheus startup arguments for production "monitoring"
#           args = [
#             "--config.file=/etc/prometheus/prometheus.yml",
#             "--storage.tsdb.path=/prometheus/",
#             "--web.console.libraries=/etc/prometheus/console_libraries",
#             "--web.console.templates=/etc/prometheus/consoles",
#             "--web.enable-lifecycle",
#             "--web.enable-admin-api",                    # Enable admin API for management
#             "--storage.tsdb.retention.time=15d",         # Keep data for 15 days locally
#             "--storage.tsdb.min-block-duration=2h",      # Optimize for remote write
#             "--storage.tsdb.max-block-duration=2h",      # Optimize for remote write
#             # "--web.enable-remote-shutdown"
#           ]

#           # Mount the configuration file
#           volume_mount {
#             name       = "prometheus-config"
#             mount_path = "/etc/prometheus"
#             read_only  = true
#           }

#           # Mount storage for local data
#           volume_mount {
#             name       = "prometheus-storage"
#             mount_path = "/prometheus"
#           }

#           # Resource limits and requests
#           resources {
#             limits = {
#               cpu    = "500m"
#               memory = "1Gi"
#             }
#             requests = {
#               cpu    = "250m"
#               memory = "512Mi"
#             }
#           }

#           # Liveness probe to check if Prometheus is running
#           liveness_probe {
#             http_get {
#               path = "/-/healthy"
#               port = 9090
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 3
#           }

#           # Readiness probe to check if Prometheus is ready to serve requests
#           readiness_probe {
#             http_get {
#               path = "/-/ready"
#               port = 9090
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 5
#             timeout_seconds       = 3
#             failure_threshold     = 3
#           }
#         }

#         # Volume for Prometheus configuration
#         volume {
#           name = "prometheus-config"
#           config_map {
#             name = kubernetes_config_map.prometheus_config.metadata[0].name
#             default_mode = "0644"
#           }
#         }

#         # Volume for Prometheus data storage
#         volume {
#           name = "prometheus-storage"
#           empty_dir {
#             size_limit = "20Gi"
#           }
#         }

#         # Security context for the pod
#         security_context {
#           run_as_non_root = true
#           run_as_user     = 65534
#           fs_group        = 65534
#         }
#       }
#     }
#   }
# }

# # =============================================================================
# # PROMETHEUS SERVICE
# # =============================================================================

# # Prometheus service
# # This exposes Prometheus within the cluster so other services can access it
# resource "kubernetes_service" "prometheus" {
#   metadata {
#     name      = "bsp-prometheus-service-${var.environment}"
#     namespace = ""monitoring""
#     labels = {
#       app = "bsp-prometheus-${var.environment}"
#       environment = var.environment
#     }
#   }

#   spec {
#     selector = {
#       app = "bsp-prometheus-${var.environment}"
#     }

#     port {
#       name        = "web"
#       port        = 9090
#       target_port = 9090
#       protocol    = "TCP"
#     }

#     type = "ClusterIP"  # Internal access only
#   }
# }

# # =============================================================================
# # PROMETHEUS RBAC (Role-Based Access Control)
# # =============================================================================

# # Cluster role for Prometheus with comprehensive permissions
# # This defines what Kubernetes resources Prometheus can access to scrape metrics
# resource "kubernetes_cluster_role" "prometheus" {
#   metadata {
#     name = "bsp-prometheus-clusterrole-${var.environment}"
#   }

#   # Allow access to basic Kubernetes resources for metrics scraping
#   rule {
#     api_groups = [""]
#     resources  = ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to configmaps (needed for service discovery)
#   rule {
#     api_groups = [""]
#     resources  = ["configmaps"]
#     verbs      = ["get"]
#   }

#   # Allow access to extensions resources
#   rule {
#     api_groups = ["extensions"]
#     resources  = ["ingresses"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to networking resources
#   rule {
#     api_groups = ["networking.k8s.io"]
#     resources  = ["ingresses"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to app resources for comprehensive "monitoring"
#   rule {
#     api_groups = ["apps"]
#     resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to batch resources
#   rule {
#     api_groups = ["batch"]
#     resources  = ["jobs", "cronjobs"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to autoscaling resources
#   rule {
#     api_groups = ["autoscaling"]
#     resources  = ["horizontalpodautoscalers"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to policy resources
#   rule {
#     api_groups = ["policy"]
#     resources  = ["poddisruptionbudgets"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to storage resources
#   rule {
#     api_groups = ["storage.k8s.io"]
#     resources  = ["storageclasses", "volumeattachments"]
#     verbs      = ["get", "list", "watch"]
#   }
# }

# # Bind the cluster role to the Prometheus service account
# # This gives Prometheus the permissions defined in the cluster role
# resource "kubernetes_cluster_role_binding" "prometheus" {
#   metadata {
#     name = "bsp-prometheus-clusterrolebinding-${var.environment}"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.prometheus.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.prometheus.metadata[0].name
#     namespace = ""monitoring""
#   }
# }

# # =============================================================================
# # OUTPUTS
# # =============================================================================

# output "prometheus_workspace_id" {
#   description = "ID of the AWS Managed Prometheus workspace"
#   value       = aws_prometheus_workspace.main.id
# }

# output "prometheus_workspace_arn" {
#   description = "ARN of the AWS Managed Prometheus workspace"
#   value       = aws_prometheus_workspace.main.arn
# }

# output "prometheus_workspace_endpoint" {
#   description = "Endpoint URL of the AWS Managed Prometheus workspace"
#   value       = aws_prometheus_workspace.main.prometheus_endpoint
# }

# output "prometheus_remote_write_url" {
#   description = "URL for Prometheus remote write to AWS Managed Prometheus"
#   value       = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.main.id}/api/v1/remote_write"
# }

# output "prometheus_query_url" {
#   description = "URL for querying AWS Managed Prometheus"
#   value       = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.main.id}/api/v1/query"
# }

# output "prometheus_service_url" {
#   description = "Internal Kubernetes service URL for Prometheus"
#   value       = "http://bsp-prometheus-service-${var.environment}."monitoring".svc.cluster.local:9090"
# }

























# # =============================================================================
# # VARIABLES - These come from your existing EKS module outputs
# # =============================================================================

# variable "eks_cluster_name" {
#   description = "Name of the EKS cluster (from your EKS module output)"
#   type        = string
# }

# variable "eks_cluster_oidc_issuer" {
#   description = "OIDC issuer URL for the EKS cluster (from your EKS module output)"
#   type        = string
# }

# variable "oidc_provider_arn" {
#   description = "ARN of the OIDC provider (from your EKS module output)"
#   type        = string
# }

# variable "aws_region" {
#   description = "AWS region where resources will be created"
#   type        = string
#   default     = "us-west-2"
# }

# # =============================================================================
# # STEP 1: CREATE AMAZON MANAGED PROMETHEUS WORKSPACE
# # This replaces the need to install Prometheus server in your cluster
# # =============================================================================

# resource "aws_prometheus_workspace" "this" {
#   alias = "eks-amp-workspace"  # Friendly name for your workspace
#   tags = {
#     Environment = "prod"
#     Project     = "eks-"monitoring""
#   }
# }
# # Result: You get a managed Prometheus service in AWS (no server to maintain)

# # =============================================================================
# # STEP 2: CREATE IAM PERMISSIONS FOR PROMETHEUS TO ACCESS AMP
# # This policy allows sending metrics to Amazon Managed Prometheus
# # =============================================================================

# resource "aws_iam_policy" "amp_remote_write_policy" {
#   name        = "EKS_AMP_RemoteWritePolicy"
#   description = "IAM policy for Prometheus remote write to Amazon Managed Prometheus"

#   # This policy allows writing metrics to AMP and querying them
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "aps:RemoteWrite",  # Permission to send metrics to AMP
#           "aps:QueryMetrics"  # Permission to query metrics from AMP
#         ]
#         Resource = aws_prometheus_workspace.this.arn  # Only for our workspace
#       }
#     ]
#   })
# }

# # =============================================================================
# # STEP 3: CREATE IAM ROLE FOR KUBERNETES SERVICE ACCOUNT (IRSA)
# # This enables pods in your EKS cluster to assume AWS IAM roles securely
# # =============================================================================

# resource "aws_iam_role" "amp_prometheus_role" {
#   name = "eks-amp-prometheus-role"

#   # This trust policy allows the specific service account to assume this role
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = var.oidc_provider_arn  # Your EKS cluster's OIDC provider
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           # Only allow the specific service account to assume this role
#           "${replace(var.eks_cluster_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:"monitoring":amp-prometheus-sa"
#         }
#       }
#     }]
#   })
# }

# # Attach the AMP policy to the role
# resource "aws_iam_role_policy_attachment" "attach_amp_policy" {
#   role       = aws_iam_role.amp_prometheus_role.name
#   policy_arn = aws_iam_policy.amp_remote_write_policy.arn
# }
# # Result: Kubernetes pods using this service account can send metrics to AMP

# # =============================================================================
# # STEP 4: CREATE KUBERNETES NAMESPACE AND SERVICE ACCOUNT
# # This creates the resources needed in your EKS cluster
# # =============================================================================

# # Create the "monitoring" namespace where all "monitoring" tools will live
# resource "kubernetes_namespace" ""monitoring"" {
#   metadata {
#     name = ""monitoring""
#   }
# }

# # Create service account with IRSA annotation
# resource "kubernetes_service_account" "amp_prometheus_sa" {
#   metadata {
#     name      = "amp-prometheus-sa"
#     namespace = "monitoring"
#     annotations = {
#       # This annotation links the service account to the IAM role
#       "eks.amazonaws.com/role-arn" = aws_iam_role.amp_prometheus_role.arn
#     }
#   }
# }
# # Result: Any pod using this service account can access AMP using AWS IAM

# # =============================================================================
# # STEP 5: DEPLOY ADOT COLLECTOR (REPLACES PROMETHEUS SERVER)
# # This is the magic component that scrapes metrics and sends to AMP
# # =============================================================================

# resource "helm_release" "adot_collector" {
#   name       = "adot-collector"
#   chart      = "adot-eks-add-on"
#   repository = "https://aws-observability.github.io/aws-otel-helm-charts"
#   namespace  = "monitoring"
#   version    = "0.37.0"

#   # Use our existing service account (don't create a new one)
#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = kubernetes_service_account.amp_prometheus_sa.metadata[0].name
#   }

#   set {
#     name  = "replicaCount"
#     value = "1"  # Single instance is enough for most cases
#   }

#   # Configuration for the ADOT collector
#   values = [
#     yamlencode({
#       awsRegion = var.aws_region
#       clusterName = var.eks_cluster_name
      
#       config = {
#         # RECEIVERS: What metrics to collect
#         receivers = {
#           prometheus = {
#             config = {
#               global = {
#                 scrape_interval = "15s"  # Collect metrics every 15 seconds
#               }
#               scrape_configs = [
#                 {
#                   # Scrape metrics from Kubernetes pods that have prometheus annotations
#                   job_name = "kubernetes-pods"
#                   kubernetes_sd_configs = [
#                     {
#                       role = "pod"
#                     }
#                   ]
#                   relabel_configs = [
#                     {
#                       # Only scrape pods with annotation: prometheus.io/scrape: "true"
#                       source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
#                       action = "keep"
#                       regex = "true"
#                     }
#                   ]
#                 },
#                 {
#                   # Scrape metrics from Kubernetes nodes (CPU, memory, etc.)
#                   job_name = "kubernetes-nodes"
#                   kubernetes_sd_configs = [
#                     {
#                       role = "node"
#                     }
#                   ]
#                   relabel_configs = [
#                     {
#                       # Use kubelet port for node metrics
#                       source_labels = ["__address__"]
#                       regex = "([^:]+):(\\d+)"
#                       target_label = "__address__"
#                       replacement = "${1}:10250"
#                     }
#                   ]
#                 }
#               ]
#             }
#           }
#         }
        
#         # EXPORTERS: Where to send the metrics
#         exporters = {
#           prometheusremotewrite = {
#             endpoint = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/remote_write"
#             auth = {
#               authenticator = "sigv4auth"  # Use AWS signature v4 for authentication
#             }
#           }
#         }
        
#         # EXTENSIONS: Additional functionality
#         extensions = {
#           sigv4auth = {
#             region = var.aws_region
#             service = "aps"  # Amazon Managed Prometheus service
#           }
#         }
        
#         # SERVICE: Connect receivers to exporters
#         service = {
#           extensions = ["sigv4auth"]
#           pipelines = {
#             metrics = {
#               receivers = ["prometheus"]              # Collect from prometheus receiver
#               exporters = ["prometheusremotewrite"]   # Send to AMP
#             }
#           }
#         }
#       }
#     })
#   ]
# }
# # Result: ADOT collector scrapes your cluster metrics and sends them to AMP

# # =============================================================================
# # STEP 6: CREATE AMAZON MANAGED GRAFANA FOR DASHBOARDS
# # This replaces the need to install Grafana server in your cluster
# # =============================================================================

# resource "aws_grafana_workspace" "this" {
#   account_access_type      = "CURRENT_ACCOUNT"  # Use current AWS account
#   authentication_providers = ["AWS_SSO"]         # Use AWS SSO for login
#   permission_type          = "SERVICE_MANAGED"   # Let AWS manage permissions
#   name                     = "eks-grafana-workspace"
#   description              = "Managed Grafana for EKS "monitoring""
#   data_sources             = ["PROMETHEUS"]      # Enable Prometheus data source
#   role_arn                 = aws_iam_role.grafana_role.arn  # Use our IAM role
  
#   tags = {
#     Environment = "prod"
#     Project     = "eks-"monitoring""
#   }
# }

# # =============================================================================
# # STEP 6A: AUTOMATICALLY CONFIGURE AMP AS DATA SOURCE IN GRAFANA
# # This eliminates manual data source configuration
# # =============================================================================

# resource "aws_grafana_workspace_api_key" "this" {
#   key_name        = "terraform-key"
#   key_role        = "ADMIN"
#   seconds_to_live = 3600
#   workspace_id    = aws_grafana_workspace.this.id
# }

# # Configure AMP as data source in Grafana
# resource "aws_grafana_workspace_data_source" "amp" {
#   workspace_id = aws_grafana_workspace.this.id
#   name         = "AmazonManagedPrometheus"
#   type         = "prometheus"
  
#   data_source_configuration = jsonencode({
#     url = aws_prometheus_workspace.this.prometheus_endpoint
#     httpMethod = "POST"
#     sigV4Auth = true
#     sigV4AuthType = "default"
#     sigV4Region = var.aws_region
#   })
# }
# # Result: Grafana workspace with AMP automatically configured as data source

# # =============================================================================
# # STEP 7: CREATE IAM PERMISSIONS FOR GRAFANA TO ACCESS AMP
# # This allows Grafana to read metrics from Amazon Managed Prometheus
# # =============================================================================

# resource "aws_iam_role" "grafana_role" {
#   name = "eks-grafana-amp-role"

#   # Allow Grafana service to assume this role
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "grafana.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# # Policy that allows Grafana to read from AMP
# resource "aws_iam_role_policy" "grafana_amp_policy" {
#   name = "GrafanaAMPPolicy"
#   role = aws_iam_role.grafana_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "aps:ListWorkspaces",     # List available workspaces
#           "aps:DescribeWorkspace",  # Get workspace details
#           "aps:QueryMetrics",       # Query metrics from AMP
#           "aps:GetLabels",          # Get metric labels
#           "aps:GetSeries",          # Get time series data
#           "aps:GetMetricMetadata"   # Get metadata about metrics
#         ]
#         Resource = "*"  # Allow access to all AMP resources
#       }
#     ]
#   })
# }
# # Result: Grafana can read metrics from AMP to create dashboards

# # =============================================================================
# # OUTPUTS - Information you'll need after deployment
# # =============================================================================

# output "prometheus_workspace_id" {
#   description = "Amazon Managed Prometheus workspace ID"
#   value       = aws_prometheus_workspace.this.id
# }

# output "prometheus_endpoint" {
#   description = "Amazon Managed Prometheus endpoint (use this in Grafana)"
#   value       = aws_prometheus_workspace.this.prometheus_endpoint
# }

# output "grafana_workspace_id" {
#   description = "Amazon Managed Grafana workspace ID"
#   value       = aws_grafana_workspace.this.id
# }

# output "grafana_endpoint" {
#   description = "Amazon Managed Grafana endpoint (use this URL to access Grafana)"
#   value       = aws_grafana_workspace.this.endpoint
# }

# output "amp_prometheus_role_arn" {
#   description = "IAM role ARN for AMP Prometheus (used by ADOT collector)"
#   value       = aws_iam_role.amp_prometheus_role.arn
# }

# # =============================================================================
# # SUMMARY OF WHAT THIS UPDATED CODE DOES:
# # 
# # 1. ✅ Creates Amazon Managed Prometheus workspace
# # 2. ✅ Sets up IAM permissions for secure access
# # 3. ✅ Creates Kubernetes namespace and service account with IRSA
# # 4. ✅ Deploys kube-state-metrics (Kubernetes resource metrics)
# # 5. ✅ Deploys node-exporter (detailed node hardware metrics)
# # 6. ✅ Deploys ADOT collector to scrape ALL metrics and send to AMP
# # 7. ✅ Creates Amazon Managed Grafana workspace
# # 8. ✅ Automatically configures AMP as data source in Grafana
# # 9. ✅ Sets up IAM permissions for Grafana to read from AMP
# # 
# # METRICS COLLECTED:
# # - 📊 Node metrics: CPU, memory, disk, network (from node-exporter)
# # - 📊 Pod metrics: CPU, memory, restarts, status (from kubelet/cAdvisor)
# # - 📊 Kubernetes resources: Deployments, ReplicaSets, Services, etc. (from kube-state-metrics)
# # - 📊 Container metrics: Resource usage, limits, requests (from cAdvisor)
# # - 📊 Custom application metrics: From apps with prometheus annotations
# #
# # NO MANUAL SETUP REQUIRED: Everything is configured automatically!
# # =============================================================================

























# # =============================================================================
# # VARIABLES - These come from your existing EKS module outputs
# # =============================================================================

# variable "eks_cluster_name" {
#   description = "Name of the EKS cluster (from your EKS module output)"
#   type        = string
# }

# variable "eks_cluster_oidc_issuer" {
#   description = "OIDC issuer URL for the EKS cluster (from your EKS module output)"
#   type        = string
# }

# variable "oidc_provider_arn" {
#   description = "ARN of the OIDC provider (from your EKS module output)"
#   type        = string
# }

# variable "aws_region" {
#   description = "AWS region where resources will be created"
#   type        = string
#   default     = "us-east-1"  # Changed to match your actual region
# }

# # =============================================================================
# # STEP 1: CREATE AMAZON MANAGED PROMETHEUS WORKSPACE
# # =============================================================================

# resource "aws_prometheus_workspace" "this" {
#   alias = "eks-amp-workspace"
#   tags = {
#     Environment = "prod"
#     Project     = "eks-monitoring"
#   }
# }

# # =============================================================================
# # STEP 2: CREATE IAM PERMISSIONS FOR PROMETHEUS TO ACCESS AMP
# # =============================================================================

# resource "aws_iam_policy" "amp_remote_write_policy" {
#   name        = "EKS_AMP_RemoteWritePolicy"
#   description = "IAM policy for Prometheus remote write to Amazon Managed Prometheus"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "aps:RemoteWrite",
#           "aps:QueryMetrics"
#         ]
#         Resource = aws_prometheus_workspace.this.arn
#       }
#     ]
#   })
# }

# # =============================================================================
# # STEP 3: CREATE IAM ROLE FOR KUBERNETES SERVICE ACCOUNT (IRSA)
# # =============================================================================

# resource "aws_iam_role" "amp_prometheus_role" {
#   name = "eks-amp-prometheus-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = var.oidc_provider_arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(var.eks_cluster_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:monitoring:amp-prometheus-sa"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_amp_policy" {
#   role       = aws_iam_role.amp_prometheus_role.name
#   policy_arn = aws_iam_policy.amp_remote_write_policy.arn
# }

# # =============================================================================
# # STEP 4: CREATE KUBERNETES NAMESPACE AND SERVICE ACCOUNT
# # =============================================================================

# resource "kubernetes_service_account" "amp_prometheus_sa" {
#   metadata {
#     name      = "amp-prometheus-sa"
#     namespace = "monitoring"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.amp_prometheus_role.arn
#     }
#   }
# }

# # =============================================================================
# # STEP 5A: DEPLOY KUBE-STATE-METRICS
# # =============================================================================

# resource "helm_release" "kube_state_metrics" {
#   name       = "kube-state-metrics"
#   chart      = "kube-state-metrics"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   namespace  = "monitoring"
#   version    = "5.15.2"

#   values = [
#     yamlencode({
#       podAnnotations = {
#         "prometheus.io/scrape" = "true"
#         "prometheus.io/port"   = "8080"
#         "prometheus.io/path"   = "/metrics"
#       }
#     })
#   ]
# }

# # =============================================================================
# # STEP 5B: DEPLOY NODE-EXPORTER
# # =============================================================================

# resource "helm_release" "node_exporter" {
#   name       = "node-exporter"
#   chart      = "prometheus-node-exporter"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   namespace  = "monitoring"
#   version    = "4.24.0"

#   values = [
#     yamlencode({
#       podAnnotations = {
#         "prometheus.io/scrape" = "true"
#         "prometheus.io/port"   = "9100"
#         "prometheus.io/path"   = "/metrics"
#       }
#       hostPID     = true
#       hostIPC     = true
#       hostNetwork = true
#     })
#   ]
# }

# # =============================================================================
# # STEP 5C: CLEANUP EXISTING CONFIGMAP BEFORE ADOT DEPLOYMENT
# # =============================================================================

# resource "null_resource" "cleanup_existing_configmap" {
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Cleaning up any existing ConfigMap..."
#       kubectl delete configmap adot-conf -n monitoring --ignore-not-found=true
#       echo "Cleanup completed"
#     EOT
#   }

#   depends_on = [
#     helm_release.kube_state_metrics,
#     helm_release.node_exporter
#   ]
# }

# # =============================================================================
# # STEP 5D: CREATE FIXED CONFIGMAP WITH PROPER CONFIGURATION
# # =============================================================================

# resource "kubernetes_config_map" "adot_config_correct" {
#   metadata {
#     name      = "adot-conf"
#     namespace = "monitoring"
#     labels = {
#       app                                        = "opentelemetry"
#       "app.kubernetes.io/component"              = "opentelemetry"
#       "app.kubernetes.io/instance"               = "adot-collector"
#       "app.kubernetes.io/managed-by"             = "Terraform"
#       "app.kubernetes.io/name"                   = "adot-exporter-for-eks-on-ec2"
#       "app.kubernetes.io/part-of"                = "adot-exporter-for-eks-on-ec2"
#       "app.kubernetes.io/version"                = "0.37.0"
#       component                                  = "adot-conf"
#     }
#     annotations = {
#       "meta.helm.sh/release-name"      = "adot-collector"
#       "meta.helm.sh/release-namespace" = "monitoring"
#       "managed-by"                     = "terraform"
#     }
#   }

#   # Add lifecycle management to handle recreation properly
#   lifecycle {
#     create_before_destroy = false
#     ignore_changes = [
#       metadata[0].resource_version,
#       metadata[0].uid
#     ]
#   }

#   data = {
#     "adot-config" = yamlencode({
#       extensions = {
#         health_check = {}
#         sigv4auth = {
#           region  = var.aws_region
#           service = "aps"
#         }
#       }
#       receivers = {
#         prometheus = {
#           config = {
#             global = {
#               scrape_interval = "30s"
#               scrape_timeout  = "10s"
#               external_labels = {
#                 cluster = var.eks_cluster_name
#                 region  = var.aws_region
#               }
#             }
#             scrape_configs = [
#               {
#                 job_name         = "kubernetes-pods"
#                 honor_timestamps = false  # CRITICAL: Fixes out-of-order timestamp issues
#                 sample_limit     = 10000
#                 metrics_path     = "/metrics"
#                 kubernetes_sd_configs = [
#                   { role = "pod" }
#                 ]
#                 relabel_configs = [
#                   {
#                     source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
#                     action        = "keep"
#                     regex         = "true"
#                   },
#                   {
#                     source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
#                     action        = "replace"
#                     regex         = "(.+)"
#                     target_label  = "__metrics_path__"
#                   },
#                   # FIXED: Proper regex replacement syntax
#                   {
#                     source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
#                     action        = "replace"
#                     regex         = "([^:]+)(?::\\d+)?;(\\d+)"
#                     replacement   = "${1}:${2}"  # FIXED: Use ${1} instead of $1
#                     target_label  = "__address__"
#                   },
#                   # Add default port for pods without port annotation
#                   {
#                     source_labels = ["__address__"]
#                     regex         = "([^:]+):$"
#                     target_label  = "__address__"
#                     replacement   = "${1}:8080"  # FIXED: Use ${1} instead of $1
#                   },
#                   {
#                     action = "labelmap"
#                     regex  = "__meta_kubernetes_pod_label_(.+)"
#                   },
#                   {
#                     source_labels = ["__meta_kubernetes_namespace"]
#                     action        = "replace"
#                     target_label  = "kubernetes_namespace"
#                   },
#                   {
#                     source_labels = ["__meta_kubernetes_pod_name"]
#                     action        = "replace"
#                     target_label  = "kubernetes_pod_name"
#                   },
#                   # FIXED: Ensure instance label is properly set
#                   {
#                     source_labels = ["__address__"]
#                     action        = "replace"
#                     target_label  = "instance"
#                   }
#                 ]
#               }
#             ]
#           }
#         }
#       }
#       processors = {
#         "memory_limiter" = {
#           limit_mib = 512
#         }
#         "batch/metrics" = {
#           timeout         = "60s"
#           send_batch_size = 1000
#           send_batch_max_size = 1500
#         }
#       }
#       exporters = {
#         prometheusremotewrite = {
#           endpoint = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/remote_write"
#           auth = {
#             authenticator = "sigv4auth"
#           }
#           retry_on_failure = {
#             enabled         = true
#             initial_interval = "5s"
#             max_interval    = "30s"
#             max_elapsed_time = "300s"
#           }
#           sending_queue = {
#             enabled      = true
#             num_consumers = 5    # REDUCED: From 10 to 5 to reduce memory pressure
#             queue_size   = 1000  # REDUCED: From 5000 to 1000
#           }
#           timeout = "30s"
#           resource_to_telemetry_conversion = {
#             enabled = false
#           }
#           # ADDED: Additional configuration to handle AMP better
#           remote_write_queue = {
#             capacity = 2500
#             max_shards = 200
#             min_shards = 1
#             max_samples_per_send = 500
#           }
#         }
#       }
#       service = {
#         extensions = ["health_check", "sigv4auth"]
#         pipelines = {
#           metrics = {
#             receivers  = ["prometheus"]
#             processors = ["memory_limiter", "batch/metrics"]
#             exporters  = ["prometheusremotewrite"]
#           }
#         }
#       }
#     })
#   }

#   depends_on = [
#     null_resource.cleanup_existing_configmap
#   ]
# }

# # =============================================================================
# # STEP 5E: DEPLOY ADOT COLLECTOR AFTER CONFIGMAP
# # =============================================================================

# resource "helm_release" "adot_collector" {
#   name       = "adot-collector"
#   chart      = "adot-exporter-for-eks-on-ec2"
#   repository = "https://aws-observability.github.io/aws-otel-helm-charts"
#   namespace  = "monitoring"

#   values = [
#     yamlencode({
#       awsRegion   = var.aws_region
#       clusterName = var.eks_cluster_name

#       adotCollector = {
#         daemonSet = {
#           namespace       = "monitoring"
#           createNamespace = false
#           serviceAccount = {
#             create = false
#             name   = kubernetes_service_account.amp_prometheus_sa.metadata[0].name
#           }
#         }
#       }

#       # Disable default ConfigMap creation to prevent conflicts
#       configMap = {
#         create = false
#       }
#     })
#   ]

#   depends_on = [
#     kubernetes_config_map.adot_config_correct
#   ]
# }

# # =============================================================================
# # STEP 5F: RESTART ADOT PODS AFTER DEPLOYMENT
# # =============================================================================

# resource "null_resource" "restart_adot_pods" {
#   triggers = {
#     config_hash = sha256(kubernetes_config_map.adot_config_correct.data["adot-config"])
#     always_run  = timestamp()
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Waiting for ADOT DaemonSet to be ready..."
#       kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2 -n monitoring --timeout=300s || true
      
#       echo "Restarting ADOT DaemonSet..."
#       kubectl rollout restart daemonset/adot-collector-daemonset -n monitoring || true
      
#       echo "Waiting for rollout to complete..."
#       kubectl rollout status daemonset/adot-collector-daemonset -n monitoring --timeout=300s || true
      
#       echo "ADOT pods status:"
#       kubectl get pods -n monitoring -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2
#     EOT
#   }

#   depends_on = [
#     helm_release.adot_collector
#   ]
# }

# # =============================================================================
# # STEP 7: CREATE IAM PERMISSIONS FOR GRAFANA TO ACCESS AMP
# # =============================================================================

# resource "aws_iam_role" "grafana_role" {
#   name = "eks-grafana-amp-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "grafana.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "grafana_amp_policy" {
#   name = "GrafanaAMPPolicy"
#   role = aws_iam_role.grafana_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "aps:ListWorkspaces",
#           "aps:DescribeWorkspace",
#           "aps:QueryMetrics",
#           "aps:GetLabels",
#           "aps:GetSeries",
#           "aps:GetMetricMetadata"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # =============================================================================
# # OUTPUTS
# # =============================================================================

# output "prometheus_workspace_id" {
#   description = "Amazon Managed Prometheus workspace ID"
#   value       = aws_prometheus_workspace.this.id
# }

# output "prometheus_endpoint" {
#   description = "Amazon Managed Prometheus endpoint"
#   value       = aws_prometheus_workspace.this.prometheus_endpoint
# }

# output "amp_prometheus_role_arn" {
#   description = "IAM role ARN for AMP Prometheus"
#   value       = aws_iam_role.amp_prometheus_role.arn
# }

# output "grafana_role_arn" {
#   description = "IAM role ARN for Grafana"
#   value       = aws_iam_role.grafana_role.arn
# }

# output "validation_commands" {
#   description = "Commands to validate the setup"
#   value = <<-EOT
# # === BASIC VALIDATION COMMANDS ===

# # 1. Check AMP workspace
# aws amp describe-workspace --workspace-id ${aws_prometheus_workspace.this.id} --region ${var.aws_region}

# # 2. Check ADOT pods
# kubectl get pods -n monitoring -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2

# # 3. Check ADOT logs for errors
# kubectl logs -n monitoring -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2 --tail=20

# # 4. Check ConfigMap
# kubectl get configmap adot-conf -n monitoring -o yaml

# # 5. Test AMP connectivity
# aws amp query-metrics --workspace-id ${aws_prometheus_workspace.this.id} --region ${var.aws_region} --query-string 'up' --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ)

# # === TROUBLESHOOTING COMMANDS ===

# # Check for scrape errors
# kubectl logs -n monitoring -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2 --tail=100 | grep "Failed to scrape"

# # Check for export errors  
# kubectl logs -n monitoring -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2 --tail=100 | grep "Exporting failed"

# # Test service connectivity
# kubectl exec -n monitoring -c adot-collector-container $(kubectl get pods -n monitoring -l app.kubernetes.io/name=adot-exporter-for-eks-on-ec2 -o jsonpath='{.items[0].metadata.name}') -- /bin/sh -c "timeout 5 cat < /dev/tcp/kube-state-metrics/8080" && echo "kube-state-metrics reachable" || echo "kube-state-metrics NOT reachable"
#   EOT
# }















#New



# =============================================================================
# EKS Metrics Scraping to Amazon Managed Prometheus (AMP)
# Complete Terraform Configuration
# =============================================================================

# Data source to get existing EKS cluster information
data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  name = var.cluster_name
}

# Data source for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
}

variable "amp_workspace_name" {
  description = "Name for the AMP workspace"
  type        = string
  default     = "eks-monitoring-workspace"
}

variable "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus components"
  type        = string
  default     = "amazon-cloudwatch"
}

# =============================================================================
# AMAZON MANAGED PROMETHEUS (AMP) WORKSPACE
# =============================================================================

# Create AMP workspace to store metrics
resource "aws_prometheus_workspace" "amp" {
  alias = var.amp_workspace_name
  
  tags = {
    Name        = var.amp_workspace_name
    Environment = "monitoring"
    Purpose     = "EKS-metrics-collection"
  }
}

# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================

# OIDC Identity Provider for EKS cluster (if not already exists)
data "tls_certificate" "eks_oidc" {
  url = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  count = length(data.aws_iam_openid_connect_provider.existing.arn) == 0 ? 1 : 0
  
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer
}

# Check if OIDC provider already exists
data "aws_iam_openid_connect_provider" "existing" {
  url = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer
}

# IAM Role for Prometheus Service Account
resource "aws_iam_role" "prometheus_service_account" {
  name = "${var.cluster_name}-prometheus-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = length(data.aws_iam_openid_connect_provider.existing.arn) > 0 ? data.aws_iam_openid_connect_provider.existing.arn : aws_iam_openid_connect_provider.eks_oidc[0].arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.existing.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.prometheus_namespace}:amp-iamproxy-ingest-service-account"
            "${replace(data.aws_eks_cluster.existing.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-prometheus-service-account-role"
  }
}

# IAM Policy for AMP access
resource "aws_iam_policy" "prometheus_amp_access" {
  name        = "${var.cluster_name}-prometheus-amp-access"
  description = "Policy for Prometheus to access AMP"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.amp.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "prometheus_amp_access" {
  role       = aws_iam_role.prometheus_service_account.name
  policy_arn = aws_iam_policy.prometheus_amp_access.arn
}

# =============================================================================
# KUBERNETES PROVIDER CONFIGURATION
# =============================================================================

provider "kubernetes" {
  host                   = data.aws_eks_cluster.existing.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.existing.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.existing.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.existing.token
  }
}

# =============================================================================
# KUBERNETES RESOURCES
# =============================================================================

# Create namespace for monitoring components
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.prometheus_namespace
  }
}

# Service Account for Prometheus
resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "amp-iamproxy-ingest-service-account"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_service_account.arn
    }
  }
}

# ConfigMap for Prometheus configuration
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "prometheus.yml" = yamlencode({
      global = {
        scrape_interval = "15s"
        evaluation_interval = "15s"
      }
      
      remote_write = [{
        url = "${aws_prometheus_workspace.amp.prometheus_endpoint}api/v1/remote_write"
        queue_config = {
          max_samples_per_send = 1000
          max_shards = 200
          capacity = 2500
        }
        write_relabel_configs = [{
          source_labels = ["__name__"]
          regex = "container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_network_receive_bytes_total|container_network_transmit_bytes_total|kube_pod_info|kube_pod_status_phase|kube_node_info|kube_node_status_condition|kube_deployment_status_replicas|kube_deployment_status_replicas_available"
          action = "keep"
        }]
      }]
      
      scrape_configs = [
        {
          job_name = "kubernetes-apiservers"
          kubernetes_sd_configs = [{
            role = "endpoints"
          }]
          scheme = "https"
          tls_config = {
            ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          }
          bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
              action = "keep"
              regex = "default;kubernetes;https"
            }
          ]
        },
        {
          job_name = "kubernetes-nodes"
          kubernetes_sd_configs = [{
            role = "node"
          }]
          scheme = "https"
          tls_config = {
            ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          }
          bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          relabel_configs = [
            {
              action = "labelmap"
              regex = "__meta_kubernetes_node_label_(.+)"
            }
          ]
        },
        {
          job_name = "kubernetes-cadvisor"
          kubernetes_sd_configs = [{
            role = "node"
          }]
          scheme = "https"
          metrics_path = "/metrics/cadvisor"
          tls_config = {
            ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          }
          bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          relabel_configs = [
            {
              action = "labelmap"
              regex = "__meta_kubernetes_node_label_(.+)"
            }
          ]
        },
        {
          job_name = "kubernetes-service-endpoints"
          kubernetes_sd_configs = [{
            role = "endpoints"
          }]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_scrape"]
              action = "keep"
              regex = true
            },
            {
              source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_path"]
              action = "replace"
              target_label = "__metrics_path__"
              regex = "(.+)"
            }
          ]
        },
        {
          job_name = "kubernetes-pods"
          kubernetes_sd_configs = [{
            role = "pod"
          }]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
              action = "keep"
              regex = true
            },
            {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
              action = "replace"
              target_label = "__metrics_path__"
              regex = "(.+)"
            }
          ]
        }
      ]
    })
  }
}

# =============================================================================
# PROMETHEUS DEPLOYMENT
# =============================================================================

# Prometheus Deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "prometheus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.prometheus.metadata[0].name

        container {
          name  = "prometheus"
          image = "prom/prometheus:latest"
          
          port {
            container_port = 9090
          }

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus/",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--web.enable-lifecycle"
          ]

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }

          resources {
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
          }
        }

        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }

        volume {
          name = "prometheus-storage"
          empty_dir {}
        }
      }
    }
  }
}

# Prometheus Service
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "prometheus"
    }
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
}

# =============================================================================
# KUBE-STATE-METRICS DEPLOYMENT
# =============================================================================

# Kube-state-metrics for cluster-level metrics
resource "kubernetes_deployment" "kube_state_metrics" {
  metadata {
    name      = "kube-state-metrics"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
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
        }
      }

      spec {
        container {
          name  = "kube-state-metrics"
          image = "k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.10.0"
          
          port {
            container_port = 8080
            name          = "http-metrics"
          }

          port {
            container_port = 8081
            name          = "telemetry"
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

          resources {
            limits = {
              memory = "256Mi"
              cpu    = "100m"
            }
            requests = {
              memory = "128Mi"
              cpu    = "50m"
            }
          }
        }
      }
    }
  }
}

# Kube-state-metrics Service
resource "kubernetes_service" "kube_state_metrics" {
  metadata {
    name      = "kube-state-metrics"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
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
    }

    port {
      name        = "telemetry"
      port        = 8081
      target_port = 8081
    }

    type = "ClusterIP"
  }
}

# =============================================================================
# CLUSTER ROLE AND BINDING FOR PROMETHEUS
# =============================================================================

resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
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

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prometheus.metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "amp_workspace_id" {
  description = "The ID of the AMP workspace"
  value       = aws_prometheus_workspace.amp.id
}

output "amp_workspace_arn" {
  description = "The ARN of the AMP workspace"
  value       = aws_prometheus_workspace.amp.arn
}

output "amp_prometheus_endpoint" {
  description = "The Prometheus endpoint URL for the AMP workspace"
  value       = aws_prometheus_workspace.amp.prometheus_endpoint
}

output "prometheus_service_account_role_arn" {
  description = "The ARN of the IAM role for Prometheus service account"
  value       = aws_iam_role.prometheus_service_account.arn
}

output "monitoring_namespace" {
  description = "The Kubernetes namespace where monitoring components are deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

# From your existing EKS outputs (include these in your main EKS configuration)
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = data.aws_eks_cluster.existing.name
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = data.aws_eks_cluster.existing.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = data.aws_eks_cluster.existing.arn
}

output "eks_cluster_version" {
  description = "The version of the EKS cluster"
  value       = data.aws_eks_cluster.existing.version
}

output "eks_cluster_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster"
  value       = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer
}