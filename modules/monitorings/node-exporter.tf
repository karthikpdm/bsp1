# # modules/monitoring/node-exporter.tf
# # This file contains all Node Exporter related resources

# # =============================================================================
# # NODE EXPORTER DAEMONSET
# # =============================================================================

# # Node Exporter DaemonSet
# # Node Exporter runs on every node in the cluster to collect node-level metrics
# # such as CPU, memory, disk, and network statistics. Benefits:
# # - Runs as a DaemonSet to ensure it runs on all nodes
# # - Collects host-level metrics from /proc, /sys, and root filesystem
# # - Provides comprehensive system metrics for monitoring
# # - Automatically discovers new nodes when they join the cluster
# # - Essential for node-level alerting and capacity planning
# resource "kubernetes_daemonset" "node_exporter" {
#   metadata {
#     name      = "node-exporter"
#     namespace = "monitoring"
#     labels = {
#       app       = "node-exporter"
#       component = "metrics"
#       purpose   = "node-monitoring"
#     }
#   }

#   spec {
#     selector {
#       match_labels = {
#         app = "node-exporter"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app       = "node-exporter"
#           component = "metrics"
#         }
#         annotations = {
#           "prometheus.io/scrape"                        = "true"
#           "prometheus.io/port"                          = "9100"
#           "prometheus.io/path"                          = "/metrics"
#           "prometheus.io/scheme"                        = "http"
#           "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
#         }
#       }

#       spec {
#         # Use host network to access node-level metrics
#         host_network = true
#         host_pid     = true
        
#         # Service account for node exporter
#         service_account_name = kubernetes_service_account.node_exporter.metadata[0].name

#         # Security context for the pod
#         security_context {
#           run_as_non_root = true
#           run_as_user     = 65534
#           fs_group        = 65534
#         }

#         container {
#           name  = "node-exporter"
#           image = "prom/node-exporter:v1.6.1"
          
#           # Container will listen on port 9100
#           port {
#             container_port = 9100
#             host_port      = 9100
#             name          = "metrics"
#             protocol      = "TCP"
#           }

#           # Node exporter command line arguments
#           # These configure what metrics to collect and how to collect them
#           args = [
#             "--path.procfs=/host/proc",                    # Path to proc filesystem
#             "--path.sysfs=/host/sys",                      # Path to sys filesystem
#             "--path.rootfs=/host/root",                    # Path to root filesystem
#             "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)",
#             "--collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$",
#             "--collector.netclass.ignored-devices=^(veth.*|docker.*|br-.*|lo)$",
#             "--collector.netdev.device-exclude=^(veth.*|docker.*|br-.*)$",
#             "--collector.cpu",                             # Enable CPU collector
#             "--collector.diskstats",                       # Enable disk stats collector
#             "--collector.filesystem",                      # Enable filesystem collector
#             "--collector.loadavg",                         # Enable load average collector
#             "--collector.meminfo",                         # Enable memory info collector
#             "--collector.netdev",                          # Enable network device collector
#             "--collector.netstat",                         # Enable network statistics collector
#             "--collector.stat",                            # Enable /proc/stat collector
#             "--collector.vmstat",                          # Enable virtual memory statistics collector
#             "--collector.systemd",                         # Enable systemd collector
#             "--collector.uname",                           # Enable uname collector
#             "--collector.version",                         # Enable version collector
#             "--collector.time",                            # Enable time collector
#             "--collector.thermal_zone",                    # Enable thermal zone collector
#             "--collector.hwmon",                           # Enable hardware monitoring collector
#             "--collector.pressure",                        # Enable pressure stall information
#             "--collector.processes",                       # Enable process collector
#             "--collector.interrupts",                      # Enable interrupts collector
#             "--collector.ksmd",                            # Enable kernel samepage merging daemon stats
#             "--collector.logind",                          # Enable logind collector
#             "--collector.meminfo_numa",                    # Enable NUMA memory info
#             "--collector.mountstats",                      # Enable mount statistics
#             "--collector.network_route",                   # Enable network route collector
#             "--collector.ntp",                             # Enable NTP collector
#             "--collector.powersupplyclass",                # Enable power supply class collector
#             "--collector.rapl",                            # Enable RAPL collector
#             "--collector.schedstat",                       # Enable scheduler statistics
#             "--collector.sockstat",                        # Enable socket statistics
#             "--collector.softnet",                         # Enable softnet statistics
#             "--collector.tcpstat",                         # Enable TCP statistics
#             "--collector.textfile",                        # Enable textfile collector
#             "--collector.textfile.directory=/host/etc/node-exporter/", # Directory for textfile collector
#             "--web.listen-address=0.0.0.0:9100",          # Listen address
#             "--web.telemetry-path=/metrics",               # Metrics endpoint path
#             "--web.disable-exporter-metrics",             # Disable exporter metrics
#             "--web.max-requests=40",                       # Maximum number of parallel requests
#             "--log.level=info",                            # Log level
#             "--log.format=logfmt"                          # Log format
#           ]

#           # Environment variables for better performance
#           env {
#             name  = "HOST_PROC"
#             value = "/host/proc"
#           }
          
#           env {
#             name  = "HOST_SYS"
#             value = "/host/sys"
#           }
          
#           env {
#             name  = "HOST_ROOT"
#             value = "/host/root"
#           }

#           env {
#             name  = "NODE_NAME"
#             value_from {
#               field_ref {
#                 field_path = "spec.nodeName"
#               }
#             }
#           }

#           # Mount host filesystems to access system metrics
#           volume_mount {
#             name       = "proc"
#             mount_path = "/host/proc"
#             read_only  = true
#           }

#           volume_mount {
#             name       = "sys"
#             mount_path = "/host/sys"
#             read_only  = true
#           }

#           volume_mount {
#             name       = "root"
#             mount_path = "/host/root"
#             read_only  = true
#           }

#           # Mount textfile directory for custom metrics
#           volume_mount {
#             name       = "textfile"
#             mount_path = "/host/etc/node-exporter"
#             read_only  = true
#           }

#           # Resource limits and requests
#           resources {
#             limits = {
#               cpu    = "250m"
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
#             capabilities {
#               drop = ["ALL"]
#             }
#           }

#           # Liveness probe to check if node exporter is healthy
#           liveness_probe {
#             http_get {
#               path = "/metrics"
#               port = 9100
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 3
#             success_threshold     = 1
#           }

#           # Readiness probe to check if node exporter is ready
#           readiness_probe {
#             http_get {
#               path = "/metrics"
#               port = 9100
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 5
#             timeout_seconds       = 3
#             failure_threshold     = 3
#             success_threshold     = 1
#           }

#           # Startup probe for slower startup
#           startup_probe {
#             http_get {
#               path = "/metrics"
#               port = 9100
#             }
#             initial_delay_seconds = 10
#             period_seconds        = 5
#             timeout_seconds       = 3
#             failure_threshold     = 30
#             success_threshold     = 1
#           }
#         }

#         # Volumes to mount host filesystems
#         volume {
#           name = "proc"
#           host_path {
#             path = "/proc"
#           }
#         }

#         volume {
#           name = "sys"
#           host_path {
#             path = "/sys"
#           }
#         }

#         volume {
#           name = "root"
#           host_path {
#             path = "/"
#           }
#         }

#         # Volume for textfile collector
#         volume {
#           name = "textfile"
#           host_path {
#             path = "/etc/node-exporter"
#             type = "DirectoryOrCreate"
#           }
#         }

#         # Tolerations to allow node exporter to run on all nodes
#         # including master nodes and nodes with taints
#         toleration {
#           effect   = "NoSchedule"
#           operator = "Exists"
#         }

#         toleration {
#           effect   = "NoExecute"
#           operator = "Exists"
#         }

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

#         toleration {
#           key      = "node.kubernetes.io/not-ready"
#           operator = "Exists"
#           effect   = "NoExecute"
#           toleration_seconds = 300
#         }

#         toleration {
#           key      = "node.kubernetes.io/unreachable"
#           operator = "Exists"
#           effect   = "NoExecute"
#           toleration_seconds = 300
#         }

#         # Priority class for node exporter
#         priority_class_name = "system-node-critical"

#         # DNS policy
#         dns_policy = "ClusterFirst"

#         # Termination grace period
#         termination_grace_period_seconds = 30

#         # Affinity rules to ensure one node exporter per node
#         affinity {
#           node_affinity {
#             required_during_scheduling_ignored_during_execution {
#               node_selector_term {
#                 match_expressions {
#                   key      = "kubernetes.io/os"
#                   operator = "In"
#                   values   = ["linux"]
#                 }
#               }
#             }
#           }
#         }
#       }
#     }

#     # Update strategy for the daemonset
#     # update_strategy {
#     #   type = "RollingUpdate"
#     #   rolling_update {
#     #     max_unavailable = "10%"
#     #   }
#     # }
#   }
# }

# # =============================================================================
# # NODE EXPORTER SERVICE ACCOUNT AND RBAC
# # =============================================================================

# # Service account for Node Exporter
# resource "kubernetes_service_account" "node_exporter" {
#   metadata {
#     name      = "node-exporter"
#     namespace = "monitoring"
#     labels = {
#       app       = "node-exporter"
#       component = "metrics"
#     }
#   }
# }

# # Cluster role for Node Exporter
# # Node exporter needs minimal permissions to function properly
# resource "kubernetes_cluster_role" "node_exporter" {
#   metadata {
#     name = "node-exporter"
#   }

#   # Allow node exporter to get node information
#   rule {
#     api_groups = [""]
#     resources  = ["nodes"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow node exporter to get node metrics
#   rule {
#     api_groups = [""]
#     resources  = ["nodes/metrics"]
#     verbs      = ["get"]
#   }

#   # Allow access to services for service discovery
#   rule {
#     api_groups = [""]
#     resources  = ["services", "endpoints"]
#     verbs      = ["get", "list", "watch"]
#   }

#   # Allow access to pods for container metrics
#   rule {
#     api_groups = [""]
#     resources  = ["pods"]
#     verbs      = ["get", "list", "watch"]
#   }
# }

# # Bind the cluster role to the service account
# resource "kubernetes_cluster_role_binding" "node_exporter" {
#   metadata {
#     name = "node-exporter"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.node_exporter.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.node_exporter.metadata[0].name
#     namespace = "monitoring"
#   }
# }

# # =============================================================================
# # NODE EXPORTER SERVICE
# # =============================================================================

# # Service for Node Exporter
# # This service allows Prometheus to discover and scrape node exporter instances
# resource "kubernetes_service" "node_exporter" {
#   metadata {
#     name      = "node-exporter"
#     namespace = "monitoring"
#     labels = {
#       app       = "node-exporter"
#       component = "metrics"
#     }
#     annotations = {
#       "prometheus.io/scrape"                        = "true"
#       "prometheus.io/port"                          = "9100"
#       "prometheus.io/path"                          = "/metrics"
#       "prometheus.io/scheme"                        = "http"
#       "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
#     }
#   }

#   spec {
#     # Selector to match node exporter pods
#     selector = {
#       app = "node-exporter"
#     }

#     # Service port configuration
#     port {
#       name        = "metrics"
#       port        = 9100
#       target_port = 9100
#       protocol    = "TCP"
#     }

#     # Service type - ClusterIP for internal cluster access
#     type = "ClusterIP"

#     # Cluster IP set to None for headless service
#     # This allows Prometheus to discover individual pod IPs
#     cluster_ip = "None"

#     # Session affinity
#     session_affinity = "None"
#   }
# }

# # =============================================================================
# # NODE EXPORTER NETWORK POLICY
# # =============================================================================

# # Network Policy for Node Exporter
# # This policy controls network access to node exporter pods
# resource "kubernetes_network_policy" "node_exporter" {
#   metadata {
#     name      = "node-exporter-network-policy"
#     namespace = "monitoring"
#     labels = {
#       app = "node-exporter"
#     }
#   }

#   spec {
#     pod_selector {
#       match_labels = {
#         app = "node-exporter"
#       }
#     }

#     policy_types = ["Ingress"]

#     # Allow ingress traffic from Prometheus pods
#     ingress {
#       from {
#         pod_selector {
#           match_labels = {
#             app = "prometheus"
#           }
#         }
#       }

#       ports {
#         port     = "9100"
#         protocol = "TCP"
#       }
#     }

#     # Allow ingress traffic from kube-system namespace (for health checks)
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             name = "kube-system"
#           }
#         }
#       }

#       ports {
#         port     = "9100"
#         protocol = "TCP"
#       }
#     }

#     # Allow ingress traffic from monitoring namespace
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             name = "monitoring"
#           }
#         }
#       }

#       ports {
#         port     = "9100"
#         protocol = "TCP"
#       }
#     }
#   }
# }

# # =============================================================================
# # NODE EXPORTER MONITORING RULES
# # =============================================================================

# # ConfigMap for Node Exporter alerting rules
# # These rules define when to trigger alerts based on node metrics
# resource "kubernetes_config_map" "node_exporter_rules" {
#   metadata {
#     name      = "node-exporter-rules"
#     namespace = "monitoring"
#     labels = {
#       app       = "node-exporter"
#       component = "rules"
#     }
#   }

#   data = {
#     "node-exporter-rules.yaml" = <<-EOT
#       groups:
#         - name: node-exporter-alerts
#           rules:
#             # Node down alert
#             - alert: NodeDown
#               expr: up{job="node-exporter"} == 0
#               for: 5m
#               labels:
#                 severity: critical
#                 component: node
#               annotations:
#                 summary: "Node {{ $labels.instance }} is down"
#                 description: "Node {{ $labels.instance }} has been down for more than 5 minutes"
#                 runbook_url: "https://runbooks.example.com/node-down"

#             # High CPU usage alert
#             - alert: HighCPUUsage
#               expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "High CPU usage on {{ $labels.instance }}"
#                 description: "CPU usage on {{ $labels.instance }} is {{ $value }}% for more than 5 minutes"

#             # Critical CPU usage alert
#             - alert: CriticalCPUUsage
#               expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
#               for: 2m
#               labels:
#                 severity: critical
#                 component: node
#               annotations:
#                 summary: "Critical CPU usage on {{ $labels.instance }}"
#                 description: "CPU usage on {{ $labels.instance }} is {{ $value }}% for more than 2 minutes"

#             # High memory usage alert
#             - alert: HighMemoryUsage
#               expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "High memory usage on {{ $labels.instance }}"
#                 description: "Memory usage on {{ $labels.instance }} is {{ $value }}% for more than 5 minutes"

#             # Critical memory usage alert
#             - alert: CriticalMemoryUsage
#               expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
#               for: 2m
#               labels:
#                 severity: critical
#                 component: node
#               annotations:
#                 summary: "Critical memory usage on {{ $labels.instance }}"
#                 description: "Memory usage on {{ $labels.instance }} is {{ $value }}% for more than 2 minutes"

#             # High disk usage alert
#             - alert: HighDiskUsage
#               expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 80
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "High disk usage on {{ $labels.instance }}"
#                 description: "Disk usage on {{ $labels.instance }} mountpoint {{ $labels.mountpoint }} is {{ $value }}%"

#             # Critical disk usage alert
#             - alert: CriticalDiskUsage
#               expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 95
#               for: 2m
#               labels:
#                 severity: critical
#                 component: node
#               annotations:
#                 summary: "Critical disk usage on {{ $labels.instance }}"
#                 description: "Disk usage on {{ $labels.instance }} mountpoint {{ $labels.mountpoint }} is {{ $value }}%"

#             # High load average alert
#             - alert: HighLoadAverage
#               expr: node_load1 > 4
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "High load average on {{ $labels.instance }}"
#                 description: "Load average on {{ $labels.instance }} is {{ $value }} for more than 5 minutes"

#             # Network interface down alert
#             - alert: NetworkInterfaceDown
#               expr: node_network_up == 0
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "Network interface {{ $labels.device }} is down on {{ $labels.instance }}"
#                 description: "Network interface {{ $labels.device }} on {{ $labels.instance }} has been down for more than 5 minutes"

#             # Disk read/write errors
#             - alert: DiskReadWriteErrors
#               expr: increase(node_disk_read_errors_total[5m]) > 0 or increase(node_disk_write_errors_total[5m]) > 0
#               for: 0m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "Disk I/O errors on {{ $labels.instance }}"
#                 description: "Disk {{ $labels.device }} on {{ $labels.instance }} has read/write errors"

#             # File descriptor usage
#             - alert: HighFileDescriptorUsage
#               expr: (node_filefd_allocated / node_filefd_maximum) * 100 > 80
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "High file descriptor usage on {{ $labels.instance }}"
#                 description: "File descriptor usage on {{ $labels.instance }} is {{ $value }}%"

#             # High network errors
#             - alert: HighNetworkErrors
#               expr: increase(node_network_receive_errs_total[5m]) > 100 or increase(node_network_transmit_errs_total[5m]) > 100
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "High network errors on {{ $labels.instance }}"
#                 description: "Network interface {{ $labels.device }} on {{ $labels.instance }} has high error rates"

#             # Node filesystem readonly
#             - alert: NodeFilesystemReadonly
#               expr: node_filesystem_readonly == 1
#               for: 5m
#               labels:
#                 severity: critical
#                 component: node
#               annotations:
#                 summary: "Filesystem is read-only on {{ $labels.instance }}"
#                 description: "Filesystem {{ $labels.mountpoint }} on {{ $labels.instance }} is read-only"

#             # Node clock skew
#             - alert: NodeClockSkew
#               expr: abs(node_timex_offset_seconds) > 0.05
#               for: 5m
#               labels:
#                 severity: warning
#                 component: node
#               annotations:
#                 summary: "Clock skew detected on {{ $labels.instance }}"
#                 description: "Clock skew on {{ $labels.instance }} is {{ $value }} seconds"

#     EOT
#   }
# }

# # =============================================================================
# # PRIORITY CLASS FOR NODE EXPORTER
# # =============================================================================

# # Priority class for Node Exporter
# # This ensures node exporter pods have high priority for scheduling
# resource "kubernetes_priority_class" "node_exporter" {
#   metadata {
#     name = "node-exporter-priority"
#   }

#   value          = 1000
#   global_default = false
#   description    = "Priority class for Node Exporter pods"
# }

# # =============================================================================
# # SERVICE MONITOR FOR PROMETHEUS OPERATOR (OPTIONAL)
# # =============================================================================

# # Service Monitor for Prometheus Operator compatibility
# # This resource is used if you're using Prometheus Operator
# resource "kubernetes_manifest" "node_exporter_service_monitor" {
#   manifest = {
#     apiVersion = "monitoring.coreos.com/v1"
#     kind       = "ServiceMonitor"
#     metadata = {
#       name      = "node-exporter"
#       namespace = "monitoring"
#       labels = {
#         app       = "node-exporter"
#         component = "metrics"
#       }
#     }
#     spec = {
#       selector = {
#         matchLabels = {
#           app = "node-exporter"
#         }
#       }
#       endpoints = [
#         {
#           port     = "metrics"
#           interval = "30s"
#           path     = "/metrics"
#           scheme   = "http"
#         }
#       ]
#     }
#   }
# }

# # =============================================================================
# # OUTPUTS
# # =============================================================================

# output "node_exporter_service_name" {
#   description = "Name of the Node Exporter service"
#   value       = kubernetes_service.node_exporter.metadata[0].name
# }

# output "node_exporter_service_namespace" {
#   description = "Namespace of the Node Exporter service"
#   value       = kubernetes_service.node_exporter.metadata[0].namespace
# }

# output "node_exporter_port" {
#   description = "Port on which Node Exporter is running"
#   value       = kubernetes_service.node_exporter.spec[0].port[0].port
# }

# output "node_exporter_metrics_path" {
#   description = "Metrics path for Node Exporter"
#   value       = "/metrics"
# }

# output "node_exporter_service_url" {
#   description = "Internal service URL for Node Exporter"
#   value       = "http://node-exporter.monitoring.svc.cluster.local:9100/metrics"
# }

# output "node_exporter_daemonset_name" {
#   description = "Name of the Node Exporter DaemonSet"
#   value       = kubernetes_daemonset.node_exporter.metadata[0].name
# }