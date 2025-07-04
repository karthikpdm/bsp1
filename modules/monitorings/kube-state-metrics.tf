# # modules/monitoring/kube-state-metrics.tf
# # This file contains all Kube State Metrics related resources

# # =============================================================================
# # KUBE STATE METRICS DEPLOYMENT
# # =============================================================================

# # Kube State Metrics Deployment
# # Kube State Metrics exposes Kubernetes object states as Prometheus metrics
# # It provides insights into the state of various Kubernetes objects such as:
# # - Deployments, ReplicaSets, DaemonSets, StatefulSets
# # - Pods, Nodes, Services, Endpoints
# # - ConfigMaps, Secrets, PersistentVolumes
# # - Jobs, CronJobs, HorizontalPodAutoscalers
# # - Namespaces, ResourceQuotas, LimitRanges
# resource "kubernetes_deployment" "kube_state_metrics" {
#   metadata {
#     name      = "kube-state-metrics"
#     namespace = "monitoring"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "metrics"
#       purpose   = "cluster-monitoring"
#     }
#   }

#   spec {
#     replicas = 1  # Single replica is sufficient for most cases

#     selector {
#       match_labels = {
#         app = "kube-state-metrics"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app       = "kube-state-metrics"
#           component = "metrics"
#         }
#         annotations = {
#           "prometheus.io/scrape"                        = "true"
#           "prometheus.io/port"                          = "8080"
#           "prometheus.io/path"                          = "/metrics"
#           "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
#         }
#       }

#       spec {
#         # Service account with necessary permissions
#         service_account_name = kubernetes_service_account.kube_state_metrics.metadata[0].name
        
#         # Security context for the pod
#         security_context {
#           run_as_non_root = true
#           run_as_user     = 65534
#           fs_group        = 2000
#         }

#         container {
#           name  = "kube-state-metrics"
#           image = "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.0"

#           # Main metrics port
#           port {
#             container_port = 8080
#             name          = "http-metrics"
#             protocol      = "TCP"
#           }

#           # Telemetry port for self-monitoring
#           port {
#             container_port = 8081
#             name          = "telemetry"
#             protocol      = "TCP"
#           }

#           # Command line arguments for kube-state-metrics
#           args = [
#             "--host=0.0.0.0",                              # Listen on all interfaces
#             "--port=8080",                                 # Main metrics port
#             "--telemetry-host=0.0.0.0",                   # Telemetry host
#             "--telemetry-port=8081",                       # Telemetry port
#             "--log-level=INFO",                            # Log level
#             "--log-format=logfmt",                         # Log format
            
#             # Metric labels allowlist - allows all labels for comprehensive monitoring
#             "--metric-labels-allowlist=pods=[*],nodes=[*],namespaces=[*],deployments=[*],replicasets=[*],services=[*],persistentvolumeclaims=[*],persistentvolumes=[*],jobs=[*],cronjobs=[*],daemonsets=[*],statefulsets=[*],configmaps=[*],secrets=[*],ingresses=[*],horizontalpodautoscalers=[*],storageclasses=[*],endpoints=[*],limitranges=[*],resourcequotas=[*],networkpolicies=[*],certificatesigningrequests=[*],leases=[*],poddisruptionbudgets=[*],replicationcontrollers=[*],volumeattachments=[*],mutatingwebhookconfigurations=[*],validatingwebhookconfigurations=[*]",
            
#             # Metric annotations allowlist - allows annotations for better context
#             "--metric-annotations-allowlist=nodes=[*],pods=[*],deployments=[*],services=[*],namespaces=[*],ingresses=[*],persistentvolumes=[*],persistentvolumeclaims=[*]",
            
#             # Resources to monitor - comprehensive list of Kubernetes resources
#             "--resources=certificatesigningrequests,configmaps,cronjobs,daemonsets,deployments,endpoints,horizontalpodautoscalers,ingresses,jobs,leases,limitranges,mutatingwebhookconfigurations,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,poddisruptionbudgets,pods,replicasets,replicationcontrollers,resourcequotas,secrets,services,statefulsets,storageclasses,validatingwebhookconfigurations,volumeattachments",
            
#             # Metric allowlist - specific metrics to expose for better performance
#             "--metric-allowlist=kube_configmap_info,kube_configmap_created,kube_cronjob_info,kube_cronjob_created,kube_cronjob_status_active,kube_cronjob_status_last_schedule_time,kube_cronjob_status_last_successful_time,kube_cronjob_spec_suspend,kube_cronjob_spec_starting_deadline_seconds,kube_cronjob_next_schedule_time,kube_daemonset_created,kube_daemonset_status_current_number_scheduled,kube_daemonset_status_desired_number_scheduled,kube_daemonset_status_number_available,kube_daemonset_status_number_misscheduled,kube_daemonset_status_number_ready,kube_daemonset_status_number_unavailable,kube_daemonset_status_observed_generation,kube_daemonset_status_updated_number_scheduled,kube_daemonset_metadata_generation,kube_daemonset_labels,kube_daemonset_annotations,kube_deployment_created,kube_deployment_spec_paused,kube_deployment_spec_replicas,kube_deployment_spec_strategy_rollingupdate_max_unavailable,kube_deployment_spec_strategy_rollingupdate_max_surge,kube_deployment_status_replicas,kube_deployment_status_replicas_available,kube_deployment_status_replicas_ready,kube_deployment_status_replicas_unavailable,kube_deployment_status_replicas_updated,kube_deployment_status_observed_generation,kube_deployment_status_condition,kube_deployment_metadata_generation,kube_deployment_labels,kube_deployment_annotations,kube_endpoint_info,kube_endpoint_created,kube_endpoint_labels,kube_endpoint_annotations,kube_horizontalpodautoscaler_info,kube_horizontalpodautoscaler_created,kube_horizontalpodautoscaler_metadata_generation,kube_horizontalpodautoscaler_spec_max_replicas,kube_horizontalpodautoscaler_spec_min_replicas,kube_horizontalpodautoscaler_spec_target_metric,kube_horizontalpodautoscaler_status_condition,kube_horizontalpodautoscaler_status_current_replicas,kube_horizontalpodautoscaler_status_desired_replicas,kube_horizontalpodautoscaler_status_target_metric,kube_horizontalpodautoscaler_labels,kube_horizontalpodautoscaler_annotations,kube_ingress_info,kube_ingress_created,kube_ingress_labels,kube_ingress_annotations,kube_job_info,kube_job_created,kube_job_spec_parallelism,kube_job_spec_completions,kube_job_spec_active_deadline_seconds,kube_job_status_active,kube_job_status_succeeded,kube_job_status_failed,kube_job_status_start_time,kube_job_status_completion_time,kube_job_status_condition,kube_job_owner,kube_job_labels,kube_job_annotations,kube_limitrange_info,kube_limitrange_created,kube_namespace_created,kube_namespace_labels,kube_namespace_annotations,kube_namespace_status_phase,kube_node_info,kube_node_created,kube_node_labels,kube_node_annotations,kube_node_spec_taint,kube_node_spec_unschedulable,kube_node_status_allocatable,kube_node_status_capacity,kube_node_status_condition,kube_persistentvolume_info,kube_persistentvolume_created,kube_persistentvolume_capacity_bytes,kube_persistentvolume_status_phase,kube_persistentvolume_claim_ref,kube_persistentvolume_labels,kube_persistentvolume_annotations,kube_persistentvolumeclaim_info,kube_persistentvolumeclaim_created,kube_persistentvolumeclaim_resource_requests_storage_bytes,kube_persistentvolumeclaim_status_phase,kube_persistentvolumeclaim_status_condition,kube_persistentvolumeclaim_labels,kube_persistentvolumeclaim_annotations,kube_pod_info,kube_pod_created,kube_pod_start_time,kube_pod_completion_time,kube_pod_owner,kube_pod_labels,kube_pod_annotations,kube_pod_status_phase,kube_pod_status_ready,kube_pod_status_scheduled,kube_pod_status_container_ready_time,kube_pod_status_condition,kube_pod_container_info,kube_pod_container_status_waiting,kube_pod_container_status_waiting_reason,kube_pod_container_status_running,kube_pod_container_status_terminated,kube_pod_container_status_terminated_reason,kube_pod_container_status_last_terminated_reason,kube_pod_container_status_ready,kube_pod_container_status_restarts_total,kube_pod_container_resource_requests,kube_pod_container_resource_limits,kube_pod_container_resource_requests_cpu_cores,kube_pod_container_resource_requests_memory_bytes,kube_pod_container_resource_limits_cpu_cores,kube_pod_container_resource_limits_memory_bytes,kube_pod_spec_volumes_persistentvolumeclaim_info,kube_pod_spec_volumes_persistentvolumeclaim_readonly,kube_replicaset_created,kube_replicaset_metadata_generation,kube_replicaset_spec_replicas,kube_replicaset_status_replicas,kube_replicaset_status_ready_replicas,kube_replicaset_status_fully_labeled_replicas,kube_replicaset_status_observed_generation,kube_replicaset_annotations,kube_replicaset_labels,kube_replicaset_owner,kube_resourcequota_info,kube_resourcequota_created,kube_secret_info,kube_secret_created,kube_secret_type,kube_secret_labels,kube_secret_annotations,kube_service_info,kube_service_created,kube_service_spec_type,kube_service_spec_external_ip,kube_service_status_load_balancer_ingress,kube_service_labels,kube_service_annotations,kube_statefulset_created,kube_statefulset_metadata_generation,kube_statefulset_spec_replicas,kube_statefulset_status_replicas,kube_statefulset_status_replicas_current,kube_statefulset_status_replicas_ready,kube_statefulset_status_replicas_updated,kube_statefulset_status_observed_generation,kube_statefulset_status_current_revision,kube_statefulset_status_update_revision,kube_statefulset_labels,kube_statefulset_annotations,kube_storageclass_info,kube_storageclass_created,kube_storageclass_labels,kube_storageclass_annotations",
            
#             # Namespace filtering (optional - remove to monitor all namespaces)
#             # "--namespaces=default,kube-system,monitoring,istio-system",
            
#             # Custom resource support
#             "--custom-resource-state-config-file=/etc/customresourcestate/config.yaml",
            
#             # Performance tuning
#             "--enable-gzip-encoding",
#             "--metric-opt-in-list=",
#             "--metric-denylist=",
#             "--metric-allowlist-cache-size=1000",
#             "--metric-annotations-allowlist-cache-size=200",
#             "--metric-labels-allowlist-cache-size=200"
#           ]

#           # Environment variables for better configuration
#           env {
#             name = "GOMAXPROCS"
#             value = "2"
#           }

#           env {
#             name = "GOGC"
#             value = "100"
#           }

#           # Mount custom resource state config
#           volume_mount {
#             name       = "customresourcestate-config"
#             mount_path = "/etc/customresourcestate"
#             read_only  = true
#           }

#           # Resource limits and requests
#           resources {
#             limits = {
#               cpu    = "200m"
#               memory = "200Mi"
#             }
#             requests = {
#               cpu    = "100m"
#               memory = "100Mi"
#             }
#           }

#           # Security context for the container
#           security_context {
#             run_as_non_root = true
#             run_as_user     = 65534
#             read_only_root_filesystem = true
#             allow_privilege_escalation = false
#             capabilities {
#               drop = ["ALL"]
#             }
#           }

#           # Liveness probe
#           liveness_probe {
#             http_get {
#               path = "/healthz"
#               port = 8080
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 3
#             success_threshold     = 1
#           }

#           # Readiness probe
#           readiness_probe {
#             http_get {
#               path = "/healthz"
#               port = 8080
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 3
#             success_threshold     = 1
#           }
#         }

#         # Volume for custom resource state configuration
#         volume {
#           name = "customresourcestate-config"
#           config_map {
#             name = kubernetes_config_map.kube_state_metrics_config.metadata[0].name
#           }
#         }

#         # Node selector to run on specific nodes (optional)
#         node_selector = {
#           "kubernetes.io/os" = "linux"
#         }

#         # Affinity rules for better pod distribution
#         affinity {
#           pod_anti_affinity {
#             preferred_during_scheduling_ignored_during_execution {
#               weight = 100
#               pod_affinity_term {
#                 label_selector {
#                   match_expressions {
#                     key      = "app"
#                     operator = "In"
#                     values   = ["kube-state-metrics"]
#                   }
#                 }
#                 topology_key = "kubernetes.io/hostname"
#               }
#             }
#           }
#         }

#         # Tolerations for scheduling flexibility
#         toleration {
#           key      = "node-role.kubernetes.io/master"
#           operator = "Exists"
#           effect   = "NoSchedule"
#         }

#         toleration {
#           key      = "node-role.kubernetes.io/control-plane"
#           operator = "Exists"
#           effect   = "NoSchedule"
#         }

#         # DNS configuration
#         dns_policy = "ClusterFirst"

#         # Termination grace period
#         termination_grace_period_seconds = 30
#       }
#     }
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS CONFIGURATION
# # =============================================================================

# # ConfigMap for custom resource state configuration
# resource "kubernetes_config_map" "kube_state_metrics_config" {
#   metadata {
#     name      = "kube-state-metrics-config"
#     namespace = "monitoring"
#     labels = {
#       app = "kube-state-metrics"
#     }
#   }

#   data = {
#     "config.yaml" = <<-EOT
#       spec:
#         resources:
#           - groupVersionKind:
#               group: argoproj.io
#               version: v1alpha1
#               kind: Application
#             labelsFromPath:
#               name: [metadata, name]
#               namespace: [metadata, namespace]
#             metricNamePrefix: argocd_application
#             metrics:
#               - name: "info"
#                 help: "Information about ArgoCD application"
#                 each:
#                   type: Info
#                   info:
#                     labelsFromPath:
#                       operation: [status, operationState, operation, initiatedBy, username]
#                       phase: [status, operationState, phase]
#                       sync_status: [status, sync, status]
#                       health_status: [status, health, status]
#                       repo_url: [spec, source, repoURL]
#                       target_revision: [spec, source, targetRevision]
                      
#           - groupVersionKind:
#               group: networking.istio.io
#               version: v1alpha3
#               kind: VirtualService
#             labelsFromPath:
#               name: [metadata, name]
#               namespace: [metadata, namespace]
#             metricNamePrefix: istio_virtualservice
#             metrics:
#               - name: "info"
#                 help: "Information about Istio VirtualService"
#                 each:
#                   type: Info
#                   info:
#                     labelsFromPath:
#                       hosts: [spec, hosts]
#                       gateways: [spec, gateways]
                      
#           - groupVersionKind:
#               group: networking.istio.io
#               version: v1alpha3
#               kind: DestinationRule
#             labelsFromPath:
#               name: [metadata, name]
#               namespace: [metadata, namespace]
#             metricNamePrefix: istio_destinationrule
#             metrics:
#               - name: "info"
#                 help: "Information about Istio DestinationRule"
#                 each:
#                   type: Info
#                   info:
#                     labelsFromPath:
#                       host: [spec, host]
#     EOT
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS SERVICE ACCOUNT AND RBAC
# # =============================================================================

# # Service account for kube-state-metrics
# resource "kubernetes_service_account" "kube_state_metrics" {
#   metadata {
#     name      = "kube-state-metrics"
#     namespace = "monitoring"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "metrics"
#     }
#   }
# }

# # Cluster role for kube-state-metrics
# # This defines what Kubernetes resources kube-state-metrics can access
# resource "kubernetes_cluster_role" "kube_state_metrics" {
#   metadata {
#     name = "kube-state-metrics"
#   }

#   # Core resources
#   rule {
#     api_groups = [""]
#     resources = [
#       "configmaps",
#       "secrets",
#       "nodes",
#       "pods",
#       "services",
#       "resourcequotas",
#       "replicationcontrollers",
#       "limitranges",
#       "persistentvolumeclaims",
#       "persistentvolumes",
#       "namespaces",
#       "endpoints"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Apps resources
#   rule {
#     api_groups = ["apps"]
#     resources = [
#       "statefulsets",
#       "daemonsets",
#       "deployments",
#       "replicasets"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Batch resources
#   rule {
#     api_groups = ["batch"]
#     resources = [
#       "cronjobs",
#       "jobs"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Autoscaling resources
#   rule {
#     api_groups = ["autoscaling"]
#     resources = [
#       "horizontalpodautoscalers"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Authentication resources
#   rule {
#     api_groups = ["authentication.k8s.io"]
#     resources = [
#       "tokenreviews"
#     ]
#     verbs = ["create"]
#   }

#   # Authorization resources
#   rule {
#     api_groups = ["authorization.k8s.io"]
#     resources = [
#       "subjectaccessreviews"
#     ]
#     verbs = ["create"]
#   }

#   # Policy resources
#   rule {
#     api_groups = ["policy"]
#     resources = [
#       "poddisruptionbudgets"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Certificates resources
#   rule {
#     api_groups = ["certificates.k8s.io"]
#     resources = [
#       "certificatesigningrequests"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Storage resources
#   rule {
#     api_groups = ["storage.k8s.io"]
#     resources = [
#       "storageclasses",
#       "volumeattachments"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Admission registration resources
#   rule {
#     api_groups = ["admissionregistration.k8s.io"]
#     resources = [
#       "mutatingwebhookconfigurations",
#       "validatingwebhookconfigurations"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Networking resources
#   rule {
#     api_groups = ["networking.k8s.io"]
#     resources = [
#       "networkpolicies",
#       "ingresses"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Coordination resources
#   rule {
#     api_groups = ["coordination.k8s.io"]
#     resources = [
#       "leases"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Custom resources for Istio
#   rule {
#     api_groups = ["networking.istio.io"]
#     resources = [
#       "virtualservices",
#       "destinationrules",
#       "gateways",
#       "serviceentries",
#       "sidecars",
#       "workloadentries"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Custom resources for ArgoCD
#   rule {
#     api_groups = ["argoproj.io"]
#     resources = [
#       "applications",
#       "appprojects"
#     ]
#     verbs = ["list", "watch"]
#   }

#   # Extensions resources
#   rule {
#     api_groups = ["extensions"]
#     resources = [
#       "ingresses"
#     ]
#     verbs = ["list", "watch"]
#   }
# }

# # Bind the cluster role to kube-state-metrics service account
# resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
#   metadata {
#     name = "kube-state-metrics"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.kube_state_metrics.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.kube_state_metrics.metadata[0].name
#     namespace = "monitoring"
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS SERVICE
# # =============================================================================

# # Service for kube-state-metrics
# resource "kubernetes_service" "kube_state_metrics" {
#   metadata {
#     name      = "kube-state-metrics"
#     namespace = "monitoring"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "metrics"
#     }
#     annotations = {
#       "prometheus.io/scrape" = "true"
#       "prometheus.io/port"   = "8080"
#       "prometheus.io/path"   = "/metrics"
#     }
#   }

#   spec {
#     selector = {
#       app = "kube-state-metrics"
#     }

#     port {
#       name        = "http-metrics"
#       port        = 8080
#       target_port = 8080
#       protocol    = "TCP"
#     }

#     port {
#       name        = "telemetry"
#       port        = 8081
#       target_port = 8081
#       protocol    = "TCP"
#     }

#     type = "ClusterIP"
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS NETWORK POLICY
# # =============================================================================

# # Network Policy for kube-state-metrics
# resource "kubernetes_network_policy" "kube_state_metrics" {
#   metadata {
#     name      = "kube-state-metrics-network-policy"
#     namespace = "monitoring"
#   }

#   spec {
#     pod_selector {
#       match_labels = {
#         app = "kube-state-metrics"
#       }
#     }

#     policy_types = ["Ingress"]

#     # Allow ingress from Prometheus
#     ingress {
#       from {
#         pod_selector {
#           match_labels = {
#             app = "prometheus"
#           }
#         }
#       }

#       ports {
#         port     = "8080"
#         protocol = "TCP"
#       }
#     }

#     # Allow ingress from monitoring namespace
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             name = "monitoring"
#           }
#         }
#       }

#       ports {
#         port     = "8080"
#         protocol = "TCP"
#       }
#     }
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS MONITORING RULES
# # =============================================================================

# # ConfigMap for kube-state-metrics alerting rules
# resource "kubernetes_config_map" "kube_state_metrics_rules" {
#   metadata {
#     name      = "kube-state-metrics-rules"
#     namespace = "monitoring"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "rules"
#     }
#   }

#   data = {
#     "kube-state-metrics-rules.yaml" = <<-EOT
#       groups:
#         - name: kube-state-metrics-alerts
#           rules:
#             # Deployment alerts
#             - alert: DeploymentReplicasMismatch
#               expr: kube_deployment_spec_replicas != kube_deployment_status_replicas_available
#               for: 5m
#               labels:
#                 severity: warning
#                 component: deployment
#               annotations:
#                 summary: "Deployment replica mismatch for {{ $labels.deployment }}"
#                 description: "Deployment {{ $labels.deployment }} in {{ $labels.namespace }} has {{ $value }} replicas available, but {{ $labels.spec_replicas }} desired"

#             # Pod alerts
#             - alert: PodCrashLooping
#               expr: increase(kube_pod_container_status_restarts_total[15m]) > 0
#               for: 5m
#               labels:
#                 severity: warning
#                 component: pod
#               annotations:
#                 summary: "Pod {{ $labels.pod }} is crash looping"
#                 description: "Pod {{ $labels.pod }} in {{ $labels.namespace }} is crash looping"

#             - alert: PodNotReady
#               expr: kube_pod_status_ready{condition="false"} == 1
#               for: 5m
#               labels:
#                 severity: warning
#                 component: pod
#               annotations:
#                 summary: "Pod {{ $labels.pod }} is not ready"
#                 description: "Pod {{ $labels.pod }} in {{ $labels.namespace }} has been not ready for more than 5 minutes"

#             # Node alerts
#             - alert: NodeNotReady
#               expr: kube_node_status_condition{condition="Ready",status="true"} == 0
#               for: 5m
#               labels:
#                 severity: critical
#                 component: node
#               annotations:
#                 summary: "Node {{ $labels.node }} is not ready"
#                 description: "Node {{ $labels.node }} has been not ready for more than 5 minutes"

#             # PVC alerts
#             - alert: PersistentVolumeClaimPending
#               expr: kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
#               for: 5m
#               labels:
#                 severity: warning
#                 component: storage
#               annotations:
#                 summary: "PVC {{ $labels.persistentvolumeclaim }} is pending"
#                 description: "PVC {{ $labels.persistentvolumeclaim }} in {{ $labels.namespace }} is pending"

#             # Job alerts
#             - alert: JobFailed
#               expr: kube_job_status_failed > 0
#               for: 5m
#               labels:
#                 severity: warning
#                 component: job
#               annotations:
#                 summary: "Job {{ $labels.job_name }} failed"
#                 description: "Job {{ $labels.job_name }} in {{ $labels.namespace }} failed"

#             # HPA alerts
#             - alert: HorizontalPodAutoscalerMaxedOut
#               expr: kube_horizontalpodautoscaler_status_current_replicas == kube_horizontalpodautoscaler_spec_max_replicas
#               for: 5m
#               labels:
#                 severity: warning
#                 component: hpa
#               annotations:
#                 summary: "HPA {{ $labels.horizontalpodautoscaler }} has reached max replicas"
#                 description: "HPA {{ $labels.horizontalpodautoscaler }} in {{ $labels.namespace }} has reached maximum replicas"

#             # Namespace alerts
#             - alert: NamespaceTerminating
#               expr: kube_namespace_status_phase{phase="Terminating"} == 1
#               for: 10m
#               labels:
#                 severity: warning
#                 component: namespace
#               annotations:
#                 summary: "Namespace {{ $labels.namespace }} is terminating"
#                 description: "Namespace {{ $labels.namespace }} has been terminating for more than 10 minutes"

#             # Service alerts
#             - alert: ServiceWithoutEndpoints
#               expr: kube_service_info unless on (service, namespace) kube_endpoint_info
#               for: 5m
#               labels:
#                 severity: warning
#                 component: service
#               annotations:
#                 summary: "Service {{ $labels.service }} has no endpoints"
#                 description: "Service {{ $labels.service }} in {{ $labels.namespace }} has no endpoints"

#             # ConfigMap and Secret alerts
#             - alert: ConfigMapMissing
#               expr: kube_pod_info unless on (pod, namespace) kube_configmap_info
#               for: 5m
#               labels:
#                 severity: warning
#                 component: configmap
#               annotations:
#                 summary: "ConfigMap referenced by pod {{ $labels.pod }} is missing"
#                 description: "Pod {{ $labels.pod }} in {{ $labels.namespace }} references a missing ConfigMap"

#     EOT
#   }
# }

# # =============================================================================
# # HORIZONTAL POD AUTOSCALER FOR KUBE STATE METRICS
# # =============================================================================

# # HPA for kube-state-metrics to handle load
# resource "kubernetes_horizontal_pod_autoscaler_v2" "kube_state_metrics" {
#   metadata {
#     name      = "kube-state-metrics-hpa"
#     namespace = "monitoring"
#   }

#   spec {
#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = kubernetes_deployment.kube_state_metrics.metadata[0].name
#     }

#     min_replicas = 1
#     max_replicas = 3

#     metric {
#       type = "Resource"
#       resource {
#         name = "cpu"
#         target {
#           type                = "Utilization"
#           average_utilization = 70
#         }
#       }
#     }

#     metric {
#       type = "Resource"
#       resource {
#         name = "memory"
#         target {
#           type                = "Utilization"
#           average_utilization = 80
#         }
#       }
#     }

#     behavior {
#       scale_up {
#         stabilization_window_seconds = 60
#         select_policy                = "Max"
#         policy {
#           type           = "Percent"
#           value          = 100
#           period_seconds = 15
#         }
#       }
#       scale_down {
#         stabilization_window_seconds = 300
#         select_policy                = "Min"
#         policy {
#           type           = "Percent"
#           value          = 100
#           period_seconds = 15
#         }
#       }
#     }
#   }
# }

# # =============================================================================
# # SERVICE MONITOR FOR PROMETHEUS OPERATOR (OPTIONAL)
# # =============================================================================

# # Service Monitor for Prometheus Operator compatibility
# resource "kubernetes_manifest" "kube_state_metrics_service_monitor" {
#   manifest = {
#     apiVersion = "monitoring.coreos.com/v1"
#     kind       = "ServiceMonitor"
#     metadata = {
#       name      = "kube-state-metrics"
#       namespace = "monitoring"
#       labels = {
#         app       = "kube-state-metrics"
#         component = "metrics"
#       }
#     }
#     spec = {
#       selector = {
#         matchLabels = {
#           app = "kube-state-metrics"
#         }
#       }
#       endpoints = [
#         {
#           port     = "http-metrics"
#           interval = "30s"
#           path     = "/metrics"
#           scheme   = "http"
#           honorLabels = true
#         },
#         {
#           port     = "telemetry"
#           interval = "30s"
#           path     = "/metrics"
#           scheme   = "http"
#         }
#       ]
#     }
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS DASHBOARD CONFIG MAP
# # =============================================================================

# # ConfigMap for Kube State Metrics dashboard
# resource "kubernetes_config_map" "kube_state_metrics_dashboard" {
#   metadata {
#     name      = "kube-state-metrics-dashboard"
#     namespace = "monitoring"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "dashboard"
#     }
#   }

#   data = {
#     "kube-state-metrics-dashboard.json" = jsonencode({
#       dashboard = {
#         id       = null
#         title    = "Kube State Metrics Dashboard"
#         tags     = ["kubernetes", "kube-state-metrics", "cluster-state"]
#         timezone = "browser"
#         refresh  = "30s"
#         time = {
#           from = "now-1h"
#           to   = "now"
#         }
#         panels = [
#           {
#             id    = 1
#             title = "Cluster Resource Overview"
#             type  = "stat"
#             gridPos = {
#               h = 4
#               w = 24
#               x = 0
#               y = 0
#             }
#             targets = [
#               {
#                 expr         = "count(kube_node_info)"
#                 legendFormat = "Nodes"
#                 refId        = "A"
#               },
#               {
#                 expr         = "count(kube_namespace_status_phase)"
#                 legendFormat = "Namespaces"
#                 refId        = "B"
#               },
#               {
#                 expr         = "count(kube_deployment_labels)"
#                 legendFormat = "Deployments"
#                 refId        = "C"
#               },
#               {
#                 expr         = "count(kube_pod_info)"
#                 legendFormat = "Pods"
#                 refId        = "D"
#               },
#               {
#                 expr         = "count(kube_service_info)"
#                 legendFormat = "Services"
#                 refId        = "E"
#               },
#               {
#                 expr         = "count(kube_persistentvolumeclaim_info)"
#                 legendFormat = "PVCs"
#                 refId        = "F"
#               }
#             ]
#           },
#           {
#             id    = 2
#             title = "Pod Status by Namespace"
#             type  = "bargauge"
#             gridPos = {
#               h = 8
#               w = 12
#               x = 0
#               y = 4
#             }
#             targets = [
#               {
#                 expr         = "sum(kube_pod_status_phase{phase=\"Running\"}) by (namespace)"
#                 legendFormat = "Running - {{namespace}}"
#                 refId        = "A"
#               },
#               {
#                 expr         = "sum(kube_pod_status_phase{phase=\"Pending\"}) by (namespace)"
#                 legendFormat = "Pending - {{namespace}}"
#                 refId        = "B"
#               },
#               {
#                 expr         = "sum(kube_pod_status_phase{phase=\"Failed\"}) by (namespace)"
#                 legendFormat = "Failed - {{namespace}}"
#                 refId        = "C"
#               }
#             ]
#           },
#           {
#             id    = 3
#             title = "Deployment Status"
#             type  = "table"
#             gridPos = {
#               h = 8
#               w = 12
#               x = 12
#               y = 4
#             }
#             targets = [
#               {
#                 expr         = "kube_deployment_spec_replicas"
#                 legendFormat = "Desired"
#                 refId        = "A"
#               },
#               {
#                 expr         = "kube_deployment_status_replicas_available"
#                 legendFormat = "Available"
#                 refId        = "B"
#               },
#               {
#                 expr         = "kube_deployment_status_replicas_unavailable"
#                 legendFormat = "Unavailable"
#                 refId        = "C"
#               }
#             ]
#           },
#           {
#             id    = 4
#             title = "Node Status"
#             type  = "stat"
#             gridPos = {
#               h = 6
#               w = 12
#               x = 0
#               y = 12
#             }
#             targets = [
#               {
#                 expr         = "kube_node_status_condition{condition=\"Ready\",status=\"true\"}"
#                 legendFormat = "Ready - {{node}}"
#                 refId        = "A"
#               },
#               {
#                 expr         = "kube_node_status_condition{condition=\"Ready\",status=\"false\"}"
#                 legendFormat = "Not Ready - {{node}}"
#                 refId        = "B"
#               }
#             ]
#           },
#           {
#             id    = 5
#             title = "PVC Status"
#             type  = "piechart"
#             gridPos = {
#               h = 6
#               w = 12
#               x = 12
#               y = 12
#             }
#             targets = [
#               {
#                 expr         = "sum(kube_persistentvolumeclaim_status_phase) by (phase)"
#                 legendFormat = "{{phase}}"
#                 refId        = "A"
#               }
#             ]
#           },
#           {
#             id    = 6
#             title = "Job Status"
#             type  = "timeseries"
#             gridPos = {
#               h = 6
#               w = 12
#               x = 0
#               y = 18
#             }
#             targets = [
#               {
#                 expr         = "kube_job_status_active"
#                 legendFormat = "Active - {{job_name}}"
#                 refId        = "A"
#               },
#               {
#                 expr         = "kube_job_status_succeeded"
#                 legendFormat = "Succeeded - {{job_name}}"
#                 refId        = "B"
#               },
#               {
#                 expr         = "kube_job_status_failed"
#                 legendFormat = "Failed - {{job_name}}"
#                 refId        = "C"
#               }
#             ]
#           },
#           {
#             id    = 7
#             title = "HPA Status"
#             type  = "timeseries"
#             gridPos = {
#               h = 6
#               w = 12
#               x = 12
#               y = 18
#             }
#             targets = [
#               {
#                 expr         = "kube_horizontalpodautoscaler_status_current_replicas"
#                 legendFormat = "Current - {{horizontalpodautoscaler}}"
#                 refId        = "A"
#               },
#               {
#                 expr         = "kube_horizontalpodautoscaler_status_desired_replicas"
#                 legendFormat = "Desired - {{horizontalpodautoscaler}}"
#                 refId        = "B"
#               }
#             ]
#           }
#         ]
#       }
#       folderId  = 0
#       overwrite = true
#     })
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS RESOURCE LIMITS
# # =============================================================================

# # Resource quota for monitoring namespace
# resource "kubernetes_resource_quota" "monitoring_quota" {
#   metadata {
#     name      = "monitoring-resource-quota"
#     namespace = "monitoring"
#   }

#   spec {
#     hard = {
#       "requests.cpu"    = "4"
#       "requests.memory" = "8Gi"
#       "limits.cpu"      = "8"
#       "limits.memory"   = "16Gi"
#       "pods"            = "50"
#       "services"        = "20"
#       "configmaps"      = "30"
#       "secrets"         = "20"
#     }
#   }
# }

# # Limit range for monitoring namespace
# resource "kubernetes_limit_range" "monitoring_limits" {
#   metadata {
#     name      = "monitoring-limit-range"
#     namespace = "monitoring"
#   }

#   spec {
#     limit {
#       type = "Container"
#       default = {
#         cpu    = "200m"
#         memory = "200Mi"
#       }
#       default_request = {
#         cpu    = "100m"
#         memory = "100Mi"
#       }
#       max = {
#         cpu    = "2"
#         memory = "4Gi"
#       }
#       min = {
#         cpu    = "10m"
#         memory = "50Mi"
#       }
#     }
#   }
# }

# # =============================================================================
# # KUBE STATE METRICS BACKUP AND RECOVERY
# # =============================================================================

# # ConfigMap for backup scripts
# resource "kubernetes_config_map" "kube_state_metrics_backup" {
#   metadata {
#     name      = "kube-state-metrics-backup"
#     namespace = "monitoring"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "backup"
#     }
#   }

#   data = {
#     "backup.sh" = <<-EOT
#       #!/bin/bash
#       # Backup script for kube-state-metrics configuration
      
#       BACKUP_DIR="/backup/kube-state-metrics"
#       TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      
#       # Create backup directory
#       mkdir -p "$BACKUP_DIR"
      
#       # Backup kube-state-metrics configuration
#       kubectl get configmap kube-state-metrics-config -n monitoring -o yaml > "$BACKUP_DIR/config_$TIMESTAMP.yaml"
#       kubectl get configmap kube-state-metrics-rules -n monitoring -o yaml > "$BACKUP_DIR/rules_$TIMESTAMP.yaml"
#       kubectl get deployment kube-state-metrics -n monitoring -o yaml > "$BACKUP_DIR/deployment_$TIMESTAMP.yaml"
#       kubectl get service kube-state-metrics -n monitoring -o yaml > "$BACKUP_DIR/service_$TIMESTAMP.yaml"
      
#       # Compress backup
#       tar -czf "$BACKUP_DIR/kube-state-metrics-backup_$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" .
      
#       # Clean up old backups (keep last 7 days)
#       find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
      
#       echo "Backup completed: $BACKUP_DIR/kube-state-metrics-backup_$TIMESTAMP.tar.gz"
#     EOT
    
#     "restore.sh" = <<-EOT
#       #!/bin/bash
#       # Restore script for kube-state-metrics configuration
      
#       BACKUP_FILE="$1"
#       TEMP_DIR="/tmp/kube-state-metrics-restore"
      
#       if [ -z "$BACKUP_FILE" ]; then
#         echo "Usage: $0 <backup_file.tar.gz>"
#         exit 1
#       fi
      
#       # Extract backup
#       mkdir -p "$TEMP_DIR"
#       tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
      
#       # Restore configurations
#       kubectl apply -f "$TEMP_DIR"/config_*.yaml
#       kubectl apply -f "$TEMP_DIR"/rules_*.yaml
#       kubectl apply -f "$TEMP_DIR"/deployment_*.yaml
#       kubectl apply -f "$TEMP_DIR"/service_*.yaml
      
#       # Clean up
#       rm -rf "$TEMP_DIR"
      
#       echo "Restore completed from: $BACKUP_FILE"
#     EOT
#   }
# }

# # =============================================================================
# # OUTPUTS
# # =============================================================================

# output "kube_state_metrics_service_name" {
#   description = "Name of the Kube State Metrics service"
#   value       = kubernetes_service.kube_state_metrics.metadata[0].name
# }

# output "kube_state_metrics_service_namespace" {
#   description = "Namespace of the Kube State Metrics service"
#   value       = kubernetes_service.kube_state_metrics.metadata[0].namespace
# }

# output "kube_state_metrics_port" {
#   description = "Port on which Kube State Metrics is running"
#   value       = kubernetes_service.kube_state_metrics.spec[0].port[0].port
# }

# output "kube_state_metrics_telemetry_port" {
#   description = "Telemetry port for Kube State Metrics"
#   value       = kubernetes_service.kube_state_metrics.spec[0].port[1].port
# }

# output "kube_state_metrics_service_url" {
#   description = "Internal service URL for Kube State Metrics"
#   value       = "http://kube-state-metrics.monitoring.svc.cluster.local:8080/metrics"
# }

# output "kube_state_metrics_deployment_name" {
#   description = "Name of the Kube State Metrics deployment"
#   value       = kubernetes_deployment.kube_state_metrics.metadata[0].name
# }

# output "kube_state_metrics_hpa_name" {
#   description = "Name of the Kube State Metrics HPA"
#   value       = kubernetes_horizontal_pod_autoscaler_v2.kube_state_metrics.metadata[0].name
# }

# output "kube_state_metrics_config_map_name" {
#   description = "Name of the Kube State Metrics config map"
#   value       = kubernetes_config_map.kube_state_metrics_config.metadata[0].name
# }

# output "kube_state_metrics_rules_config_map_name" {
#   description = "Name of the Kube State Metrics rules config map"
#   value       = kubernetes_config_map.kube_state_metrics_rules.metadata[0].name
# }