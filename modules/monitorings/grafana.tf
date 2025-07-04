# # # modules/monitoring/grafana.tf
# # # This file contains all AWS Managed Grafana related resources

# # # =============================================================================
# # # AWS MANAGED GRAFANA WORKSPACE
# # # =============================================================================

# # # AWS Managed Grafana Workspace
# # # This creates a fully managed Grafana instance that will be used to visualize
# # # metrics from AWS Managed Prometheus. Benefits:
# # # - Fully managed service with automatic scaling and updates
# # # - Integrates seamlessly with AWS services
# # # - Built-in authentication with AWS SSO
# # # - Pre-configured dashboards and data sources
# # # - High availability and automatic backups
# # resource "aws_grafana_workspace" "main" {
# #   account_access_type      = "CURRENT_ACCOUNT"  # Access only from current AWS account
# #   authentication_providers = ["AWS_SSO"]        # Use AWS Single Sign-On for authentication
# #   permission_type         = "SERVICE_MANAGED"   # Let AWS manage permissions
# #   role_arn               = aws_iam_role.grafana_role.arn
# #   name                   = "eks-grafana-workspace"
# #   description            = "Grafana workspace for EKS cluster monitoring and observability dashboards"
  
# #   # Enable Prometheus as a data source
# #   data_sources = ["PROMETHEUS"]
  
# #   # Enable notification destinations
# #   notification_destinations = ["SNS"]
  
# #   # Grafana version and configuration
# #   grafana_version = "9.4"
  
# #   tags = {
# #     Name        = "production-grafana-workspace"
# #     Environment = "production"
# #     Purpose     = "EKS-monitoring"
# #     Team        = "DevOps"
# #     CostCenter  = "infrastructure"
# #   }
# # }

# # # =============================================================================
# # # IAM ROLES AND POLICIES FOR GRAFANA
# # # =============================================================================

# # # IAM Role for Grafana Service
# # # This role allows AWS Managed Grafana to access Prometheus and other AWS services
# # resource "aws_iam_role" "grafana_role" {
# #   name = "grafana-service-role"

# #   # Trust policy allowing Grafana service to assume this role
# #   assume_role_policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Action = "sts:AssumeRole"
# #         Effect = "Allow"
# #         Principal = {
# #           Service = "grafana.amazonaws.com"
# #         }
# #       }
# #     ]
# #   })

# #   tags = {
# #     Name        = "grafana-service-role"
# #     Environment = "production"
# #     Purpose     = "grafana-service"
# #   }
# # }

# # # IAM Policy for Grafana to access Prometheus and AWS services
# # # This policy defines what actions Grafana can perform
# # resource "aws_iam_policy" "grafana_policy" {
# #   name        = "grafana-access-policy"
# #   description = "Comprehensive policy for AWS Managed Grafana to access Prometheus and AWS services"

# #   policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         # Permissions for accessing AWS Managed Prometheus
# #         Effect = "Allow"
# #         Action = [
# #           "aps:ListWorkspaces",              # List all Prometheus workspaces
# #           "aps:DescribeWorkspace",           # Get details of Prometheus workspaces
# #           "aps:QueryMetrics",                # Query metrics from Prometheus
# #           "aps:GetLabels",                   # Get metric labels
# #           "aps:GetSeries",                   # Get time series data
# #           "aps:GetMetricMetadata",           # Get metadata about metrics
# #           "aps:ListRules",                   # List alerting rules
# #           "aps:ListRuleGroupsNamespaces",    # List rule group namespaces
# #           "aps:DescribeRuleGroupsNamespace", # Describe rule groups
# #           "aps:GetAlertManagerStatus",       # Get alert manager status
# #           "aps:GetAlertManagerDefinition"    # Get alert manager definition
# #         ]
# #         Resource = "*"
# #       },
# #       {
# #         # Permissions for accessing EC2 and EKS information
# #         Effect = "Allow"
# #         Action = [
# #           "ec2:DescribeInstances",           # Get EC2 instance information
# #           "ec2:DescribeRegions",             # Get available AWS regions
# #           "ec2:DescribeAvailabilityZones",   # Get availability zones
# #           "ec2:DescribeVpcs",                # Get VPC information
# #           "ec2:DescribeSubnets",             # Get subnet information
# #           "ec2:DescribeSecurityGroups",      # Get security group information
# #           "eks:DescribeCluster",             # Get EKS cluster details
# #           "eks:ListClusters",                # List EKS clusters
# #           "eks:DescribeNodegroup",           # Get EKS node group details
# #           "eks:ListNodegroups",              # List EKS node groups
# #           "eks:DescribeAddon",               # Get EKS addon details
# #           "eks:ListAddons"                   # List EKS addons
# #         ]
# #         Resource = "*"
# #       },
# #       {
# #         # Permissions for CloudWatch integration
# #         Effect = "Allow"
# #         Action = [
# #           "cloudwatch:DescribeAlarms",       # Get CloudWatch alarms
# #           "cloudwatch:ListMetrics",          # List CloudWatch metrics
# #           "cloudwatch:GetMetricStatistics",  # Get metric statistics
# #           "cloudwatch:GetMetricData",        # Get metric data
# #           "cloudwatch:GetInsightRuleReport", # Get insight rule reports
# #           "logs:DescribeLogGroups",          # Get log groups
# #           "logs:DescribeLogStreams",         # Get log streams
# #           "logs:GetLogEvents",               # Get log events
# #           "logs:StartQuery",                 # Start log insights queries
# #           "logs:StopQuery",                  # Stop log insights queries
# #           "logs:GetQueryResults",            # Get query results
# #           "logs:DescribeQueries"             # Describe queries
# #         ]
# #         Resource = "*"
# #       },
# #       {
# #         # Permissions for SNS notifications
# #         Effect = "Allow"
# #         Action = [
# #           "sns:Publish",                     # Publish messages to SNS topics
# #           "sns:ListTopics",                  # List SNS topics
# #           "sns:GetTopicAttributes",          # Get topic attributes
# #           "sns:ListSubscriptions",           # List subscriptions
# #           "sns:ListSubscriptionsByTopic"     # List subscriptions by topic
# #         ]
# #         Resource = "*"
# #       },
# #       {
# #         # Permissions for X-Ray tracing (if needed)
# #         Effect = "Allow"
# #         Action = [
# #           "xray:BatchGetTraces",
# #           "xray:GetServiceGraph",
# #           "xray:GetTimeSeriesServiceStatistics",
# #           "xray:GetTraceSummaries",
# #           "xray:GetTraceGraph"
# #         ]
# #         Resource = "*"
# #       }
# #     ]
# #   })
# # }

# # # Attach the policy to the Grafana service role
# # resource "aws_iam_role_policy_attachment" "grafana_policy_attachment" {
# #   role       = aws_iam_role.grafana_role.name
# #   policy_arn = aws_iam_policy.grafana_policy.arn
# # }

# # # =============================================================================
# # # SNS TOPIC FOR GRAFANA ALERTS
# # # =============================================================================

# # # SNS Topic for Grafana Alerts
# # # This topic will receive alert notifications from Grafana
# # resource "aws_sns_topic" "grafana_alerts" {
# #   name = "grafana-alerts-topic"
  
# #   # Enable server-side encryption
# #   kms_master_key_id = "alias/aws/sns"
  
# #   tags = {
# #     Name        = "grafana-alerts"
# #     Environment = "production"
# #     Purpose     = "grafana-notifications"
# #   }
# # }

# # # SNS Topic Policy
# # # This policy allows Grafana to publish messages to the SNS topic
# # resource "aws_sns_topic_policy" "grafana_alerts_policy" {
# #   arn = aws_sns_topic.grafana_alerts.arn

# #   policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Effect = "Allow"
# #         Principal = {
# #           AWS = aws_iam_role.grafana_role.arn
# #         }
# #         Action = [
# #           "sns:Publish",
# #           "sns:GetTopicAttributes"
# #         ]
# #         Resource = aws_sns_topic.grafana_alerts.arn
# #       }
# #     ]
# #   })
# # }

# # # Email subscription for alerts (optional)
# # resource "aws_sns_topic_subscription" "grafana_alerts_email" {
# #   count     = length(var.alert_email_addresses) > 0 ? length(var.alert_email_addresses) : 0
# #   topic_arn = aws_sns_topic.grafana_alerts.arn
# #   protocol  = "email"
# #   endpoint  = var.alert_email_addresses[count.index]
# # }

# # # =============================================================================
# # # GRAFANA WORKSPACE CONFIGURATION
# # # =============================================================================

# # # Configure Grafana workspace with data sources and dashboards
# # # This configuration sets up the Prometheus data source and basic dashboards
# # resource "aws_grafana_workspace_configuration" "main" {
# #   workspace_id = aws_grafana_workspace.main.id
  
# #   # Configuration in JSON format for Grafana
# #   configuration = jsonencode({
# #     # Data sources configuration
# #     datasources = {
# #       datasources = [
# #         {
# #           name      = "AWS-Managed-Prometheus"
# #           type      = "prometheus"
# #           access    = "proxy"
# #           url       = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.main.id}/"
# #           isDefault = true
# #           version   = 1
# #           editable  = true
# #           jsonData = {
# #             httpMethod             = "GET"
# #             sigV4Auth              = true
# #             sigV4AuthType          = "workspace-iam-role"
# #             sigV4Region            = data.aws_region.current.name
# #             timeInterval           = "30s"
# #             queryTimeout           = "300s"
# #             customQueryParameters  = ""
# #             manageAlerts          = true
# #             alertmanagerUid       = ""
# #             prometheusType        = "Prometheus"
# #             prometheusVersion     = "2.45.0"
# #             cacheLevel            = "Low"
# #             disableMetricsLookup  = false
# #             incrementalQuerying   = false
# #             exemplarTraceIdDestinations = []
# #           }
# #         }
# #       ]
# #     }
    
# #     # Notification channels configuration
# #     notifiers = {
# #       notifiers = [
# #         {
# #           name = "SNS-Alert-Channel"
# #           type = "sns"
# #           uid  = "sns-alerts"
# #           settings = {
# #             topic     = aws_sns_topic.grafana_alerts.arn
# #             subject   = "Grafana Alert - EKS Cluster"
# #             message   = "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
# #             body      = "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
# #             access_key = ""
# #             secret_key = ""
# #             region     = data.aws_region.current.name
# #           }
# #         }
# #       ]
# #     }
# #   })
# # }

# # # =============================================================================
# # # GRAFANA API KEY FOR DASHBOARD MANAGEMENT
# # # =============================================================================

# # # API Key for Grafana
# # # This key can be used to programmatically manage Grafana dashboards
# # resource "aws_grafana_workspace_api_key" "main" {
# #   key_name        = "terraform-dashboard-management"
# #   key_role        = "ADMIN"
# #   seconds_to_live = 2592000  # 30 days
# #   workspace_id    = aws_grafana_workspace.main.id
# # }

# # # =============================================================================
# # # GRAFANA DASHBOARD DEFINITIONS
# # # =============================================================================

# # # Local values for comprehensive Kubernetes dashboard definitions
# # locals {
# #   # Kubernetes Cluster Overview Dashboard
# #   kubernetes_cluster_dashboard = {
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Cluster Overview"
# #       tags     = ["kubernetes", "cluster", "overview", "eks"]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "Cluster Status"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_node_info)"
# #               legendFormat = "Total Nodes"
# #               refId        = "A"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               color = {
# #                 mode = "palette-classic"
# #               }
# #               unit = "short"
# #               thresholds = {
# #                 mode = "absolute"
# #                 steps = [
# #                   {
# #                     color = "green"
# #                     value = null
# #                   }
# #                 ]
# #               }
# #             }
# #           }
# #         },
# #         {
# #           id    = 2
# #           title = "Total Pods"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 6
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_pod_info)"
# #               legendFormat = "Total Pods"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 3
# #           title = "Total Deployments"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 12
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_deployment_labels)"
# #               legendFormat = "Deployments"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 4
# #           title = "Total Services"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 18
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_service_info)"
# #               legendFormat = "Services"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 5
# #           title = "Node CPU Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 4
# #           }
# #           targets = [
# #             {
# #               expr         = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
# #               legendFormat = "{{instance}}"
# #               refId        = "A"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               color = {
# #                 mode = "palette-classic"
# #               }
# #               unit = "percent"
# #               min  = 0
# #               max  = 100
# #               thresholds = {
# #                 mode = "absolute"
# #                 steps = [
# #                   {
# #                     color = "green"
# #                     value = null
# #                   },
# #                   {
# #                     color = "yellow"
# #                     value = 70
# #                   },
# #                   {
# #                     color = "red"
# #                     value = 90
# #                   }
# #                 ]
# #               }
# #             }
# #           }
# #         },
# #         {
# #           id    = 6
# #           title = "Node Memory Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 4
# #           }
# #           targets = [
# #             {
# #               expr         = "100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)"
# #               legendFormat = "{{instance}}"
# #               refId        = "A"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               color = {
# #                 mode = "palette-classic"
# #               }
# #               unit = "percent"
# #               min  = 0
# #               max  = 100
# #             }
# #           }
# #         },
# #         {
# #           id    = 7
# #           title = "Pod Status Distribution"
# #           type  = "piechart"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 12
# #           }
# #           targets = [
# #             {
# #               expr         = "sum by (phase) (kube_pod_status_phase)"
# #               legendFormat = "{{phase}}"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 8
# #           title = "Network Traffic"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 12
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(node_network_receive_bytes_total[5m])) by (instance)"
# #               legendFormat = "RX - {{instance}}"
# #               refId        = "A"
# #             },
# #             {
# #               expr         = "sum(rate(node_network_transmit_bytes_total[5m])) by (instance)"
# #               legendFormat = "TX - {{instance}}"
# #               refId        = "B"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "binBps"
# #             }
# #           }
# #         }
# #       ]
# #     }
# #     folderId  = 0
# #     overwrite = true
# #   }
  
# #   # Kubernetes Pods Dashboard
# #   kubernetes_pods_dashboard = {
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Pods Monitoring"
# #       tags     = ["kubernetes", "pods", "containers"]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "Pod Restarts"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "increase(kube_pod_container_status_restarts_total[5m])"
# #               legendFormat = "{{namespace}}/{{pod}}"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 2
# #           title = "Pod CPU Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(container_cpu_usage_seconds_total{container!=\"POD\",container!=\"\"}[5m])) by (namespace, pod)"
# #               legendFormat = "{{namespace}}/{{pod}}"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 3
# #           title = "Pod Memory Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(container_memory_working_set_bytes{container!=\"POD\",container!=\"\"}) by (namespace, pod)"
# #               legendFormat = "{{namespace}}/{{pod}}"
# #               refId        = "A"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "bytes"
# #             }
# #           }
# #         },
# #         {
# #           id    = 4
# #           title = "Pod Network I/O"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(container_network_receive_bytes_total[5m])) by (namespace, pod)"
# #               legendFormat = "RX - {{namespace}}/{{pod}}"
# #               refId        = "A"
# #             },
# #             {
# #               expr         = "sum(rate(container_network_transmit_bytes_total[5m])) by (namespace, pod)"
# #               legendFormat = "TX - {{namespace}}/{{pod}}"
# #               refId        = "B"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "binBps"
# #             }
# #           }
# #         }
# #       ]
# #     }
# #     folderId  = 0
# #     overwrite = true
# #   }
  
# #   # Kubernetes Deployments Dashboard
# #   kubernetes_deployments_dashboard = {
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Deployments Monitoring"
# #       tags     = ["kubernetes", "deployments", "workloads"]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "Deployment Status"
# #           type  = "table"
# #           gridPos = {
# #             h = 8
# #             w = 24
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "kube_deployment_spec_replicas"
# #               legendFormat = "{{deployment}}"
# #               refId        = "A"
# #             },
# #             {
# #               expr         = "kube_deployment_status_replicas_available"
# #               legendFormat = "{{deployment}}"
# #               refId        = "B"
# #             }
# #           ]
# #           transformations = [
# #             {
# #               id = "merge"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 2
# #           title = "Deployment Replica Status"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "kube_deployment_spec_replicas"
# #               legendFormat = "Desired - {{deployment}}"
# #               refId        = "A"
# #             },
# #             {
# #               expr         = "kube_deployment_status_replicas_available"
# #               legendFormat = "Available - {{deployment}}"
# #               refId        = "B"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 3
# #           title = "Deployment Health"
# #           type  = "stat"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "kube_deployment_status_condition{condition=\"Available\",status=\"true\"}"
# #               legendFormat = "{{deployment}}"
# #               refId        = "A"
# #             }
# #           ]
# #         }
# #       ]
# #     }
# #     folderId  = 0
# #     overwrite = true
# #   }
  
# #   # Kubernetes Namespaces Dashboard
# #   kubernetes_namespaces_dashboard = {
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Namespaces Monitoring"
# #       tags     = ["kubernetes", "namespaces", "resources"]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "CPU Usage by Namespace"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(container_cpu_usage_seconds_total{container!=\"POD\",container!=\"\"}[5m])) by (namespace)"
# #               legendFormat = "{{namespace}}"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 2
# #           title = "Memory Usage by Namespace"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(container_memory_working_set_bytes{container!=\"POD\",container!=\"\"}) by (namespace)"
# #               legendFormat = "{{namespace}}"
# #               refId        = "A"
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "bytes"
# #             }
# #           }
# #         },
# #         {
# #           id    = 3
# #           title = "Pods per Namespace"
# #           type  = "stat"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_pod_info) by (namespace)"
# #               legendFormat = "{{namespace}}"
# #               refId        = "A"
# #             }
# #           ]
# #         },
# #         {
# #           id    = 4
# #           title = "Services per Namespace"
# #           type  = "stat"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_service_info) by (namespace)"
# #               legendFormat = "{{namespace}}"
# #               refId        = "A"
# #             }
# #           ]
# #         }
# #       ]
# #     }
# #     folderId  = 0
# #     overwrite = true
# #   }
# # }

# # # =============================================================================
# # # VARIABLES (HARDCODED VALUES)
# # # =============================================================================

# # # Hardcoded alert email addresses
# # variable "alert_email_addresses" {
# #   description = "List of email addresses for alerts"
# #   type        = list(string)
# #   default     = [
# #     "karthik.bm@trianz.com",
# #     # "alerts@yourcompany.com"
# #   ]
# # }

# # # =============================================================================
# # # OUTPUTS
# # # =============================================================================

# # output "grafana_workspace_id" {
# #   description = "ID of the AWS Managed Grafana workspace"
# #   value       = aws_grafana_workspace.main.id
# # }

# # output "grafana_workspace_arn" {
# #   description = "ARN of the AWS Managed Grafana workspace"
# #   value       = aws_grafana_workspace.main.arn
# # }

# # output "grafana_workspace_endpoint" {
# #   description = "Endpoint URL of the AWS Managed Grafana workspace"
# #   value       = aws_grafana_workspace.main.endpoint
# # }

# # output "grafana_dashboard_url" {
# #   description = "URL to access Grafana dashboard"
# #   value       = "https://${aws_grafana_workspace.main.endpoint}"
# # }

# # output "grafana_api_key" {
# #   description = "API key for Grafana workspace (sensitive)"
# #   value       = aws_grafana_workspace_api_key.main.key
# #   sensitive   = true
# # }

# # output "grafana_role_arn" {
# #   description = "ARN of the Grafana service IAM role"
# #   value       = aws_iam_role.grafana_role.arn
# # }

# # output "sns_topic_arn" {
# #   description = "ARN of the SNS topic for Grafana alerts"
# #   value       = aws_sns_topic.grafana_alerts.arn
# # }

# # output "grafana_workspace_url" {
# #   description = "Direct URL to access Grafana workspace"
# #   value       = "https://${aws_grafana_workspace.main.endpoint}"
# # }   


# # modules/monitoring/grafana.tf
# # This file contains AWS Managed Grafana setup for EKS monitoring
# # Simplified version focused on core monitoring dashboards without complex alerting

# # =============================================================================
# # AWS MANAGED GRAFANA WORKSPACE
# # =============================================================================

# # AWS Managed Grafana Workspace
# # Creates a fully managed Grafana instance for visualizing metrics from AWS Managed Prometheus
# # Benefits:
# # - Fully managed service with automatic scaling and updates
# # - Built-in authentication with AWS SSO
# # - Seamless integration with AWS Managed Prometheus
# # - High availability and automatic backups
# # modules/monitoring/grafana.tf
# # This file contains AWS Managed Grafana setup for EKS monitoring
# # Simplified version focused on core monitoring dashboards without complex alerting

# # =============================================================================
# # AWS MANAGED GRAFANA WORKSPACE
# # modules/monitoring/grafana.tf
# # This file contains AWS Managed Grafana setup for EKS monitoring
# # Simplified version focused on core monitoring dashboards without complex alerting

# # =============================================================================
# # AWS MANAGED GRAFANA WORKSPACE
# # =============================================================================

# # AWS Managed Grafana Workspace
# # Creates a fully managed Grafana instance for visualizing metrics from AWS Managed Prometheus
# # Benefits:
# # - Fully managed service with automatic scaling and updates
# # - Built-in authentication with AWS SSO
# # - Seamless integration with AWS Managed Prometheus
# # - High availability and automatic backups
# # resource "aws_grafana_workspace" "main" {
# #   account_access_type      = "CURRENT_ACCOUNT"  # Access only from current AWS account
# #   authentication_providers = ["AWS_SSO"]        # Use AWS Single Sign-On for authentication
# #   permission_type         = "SERVICE_MANAGED"   # Let AWS manage permissions
# #   role_arn               = aws_iam_role.grafana_role.arn
# #   name                   = "bsp-eks-grafana-workspace-${var.environment}"
# #   description            = "Grafana workspace for EKS cluster monitoring and observability dashboards"
  
# #   # Enable Prometheus as a data source
# #   data_sources = ["PROMETHEUS"]
  
# #   # Grafana version
# #   grafana_version = "9.4"
  
# #   tags = {
# #     Name        = "bsp-grafana-workspace-${var.environment}"
# #     Environment = var.environment
# #     Purpose     = "EKS-monitoring"
# #     Team        = "DevOps"
# #     ClusterName = var.cluster_name
# #   }
# # }

# # # =============================================================================
# # # IAM ROLES AND POLICIES FOR GRAFANA
# # # =============================================================================

# # # IAM Role for Grafana Service
# # # This role allows AWS Managed Grafana to access Prometheus and other AWS services
# # resource "aws_iam_role" "grafana_role" {
# #   name = "bsp-grafana-service-role-${var.environment}"

# #   # Trust policy allowing Grafana service to assume this role
# #   assume_role_policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Action = "sts:AssumeRole"
# #         Effect = "Allow"
# #         Principal = {
# #           Service = "grafana.amazonaws.com"
# #         }
# #       }
# #     ]
# #   })

# #   tags = {
# #     Name        = "bsp-grafana-service-role-${var.environment}"
# #     Environment = var.environment
# #     Purpose     = "grafana-service"
# #   }
# # }

# # # IAM Policy for Grafana to access Prometheus and basic AWS services
# # # This policy defines what actions Grafana can perform
# # resource "aws_iam_policy" "grafana_policy" {
# #   name        = "bsp-grafana-access-policy-${var.environment}"
# #   description = "Policy for AWS Managed Grafana to access Prometheus and basic AWS services"

# #   policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         # Permissions for accessing AWS Managed Prometheus
# #         Effect = "Allow"
# #         Action = [
# #           "aps:ListWorkspaces",              # List all Prometheus workspaces
# #           "aps:DescribeWorkspace",           # Get details of Prometheus workspaces
# #           "aps:QueryMetrics",                # Query metrics from Prometheus
# #           "aps:GetLabels",                   # Get metric labels
# #           "aps:GetSeries",                   # Get time series data
# #           "aps:GetMetricMetadata"            # Get metadata about metrics
# #         ]
# #         Resource = "*"
# #       },
# #       {
# #         # Basic permissions for accessing EKS information
# #         Effect = "Allow"
# #         Action = [
# #           "eks:DescribeCluster",             # Get EKS cluster details
# #           "eks:ListClusters",                # List EKS clusters
# #           "ec2:DescribeInstances",           # Get EC2 instance information
# #           "ec2:DescribeRegions"              # Get available AWS regions
# #         ]
# #         Resource = "*"
# #       }
# #     ]
# #   })
# # }

# # # Attach the policy to the Grafana service role
# # resource "aws_iam_role_policy_attachment" "grafana_policy_attachment" {
# #   role       = aws_iam_role.grafana_role.name
# #   policy_arn = aws_iam_policy.grafana_policy.arn
# # }

# # # =============================================================================
# # # GRAFANA API KEY FOR PROGRAMMATIC ACCESS
# # # =============================================================================

# # # API Key for Grafana workspace
# # # This key is used to programmatically configure Grafana data sources and dashboards
# # resource "aws_grafana_workspace_api_key" "dashboard_management" {
# #   key_name        = "bsp-terraform-dashboard-management-${var.environment}"
# #   key_role        = "ADMIN"
# #   seconds_to_live = 2592000  # 30 days
# #   workspace_id    = aws_grafana_workspace.main.id
# # }

# # # =============================================================================
# # # LOCAL VALUES FOR CONFIGURATION
# # # =============================================================================

# # locals {
# #   # Prometheus data source configuration for Grafana
# #   prometheus_datasource_config = {
# #     name       = "AWS-Managed-Prometheus-${var.environment}"
# #     type       = "prometheus"
# #     access     = "proxy"
# #     url        = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.main.id}/"
# #     is_default = true
# #     uid        = "prometheus-${var.environment}"
    
# #     json_data = {
# #       httpMethod      = "GET"
# #       sigV4Auth       = true
# #       sigV4AuthType   = "workspace-iam-role"
# #       sigV4Region     = data.aws_region.current.name
# #       timeInterval    = "30s"
# #       queryTimeout    = "300s"
# #       prometheusType  = "Prometheus"
# #       prometheusVersion = "2.45.0"
# #     }
# #   }

# #   # Dashboard folder configuration
# #   dashboard_folder_config = {
# #     title = "EKS Monitoring Dashboards"
# #     uid   = "eks-monitoring-${var.environment}"
# #   }
# # }

# # # =============================================================================
# # # GRAFANA CONFIGURATION VIA API CALLS (WINDOWS COMPATIBLE)
# # # =============================================================================

# # # Create JSON file for datasource configuration
# # resource "local_file" "datasource_config" {
# #   filename = "${path.module}/temp/datasource-config.json"
# #   content = jsonencode({
# #     name       = local.prometheus_datasource_config.name
# #     type       = local.prometheus_datasource_config.type
# #     access     = local.prometheus_datasource_config.access
# #     url        = local.prometheus_datasource_config.url
# #     isDefault  = local.prometheus_datasource_config.is_default
# #     uid        = local.prometheus_datasource_config.uid
# #     jsonData   = local.prometheus_datasource_config.json_data
# #   })
# # }

# # # Create JSON file for folder configuration
# # resource "local_file" "folder_config" {
# #   filename = "${path.module}/temp/folder-config.json"
# #   content = jsonencode({
# #     title = local.dashboard_folder_config.title
# #     uid   = local.dashboard_folder_config.uid
# #   })
# # }

# # # Configure Prometheus data source using null_resource with API calls
# # # This is the workaround since aws_grafana_workspace_configuration doesn't exist
# # # WINDOWS COMPATIBLE VERSION - using temporary files instead of inline JSON
# # resource "null_resource" "configure_grafana_datasource" {
# #   depends_on = [
# #     aws_grafana_workspace.main,
# #     aws_grafana_workspace_api_key.dashboard_management,
# #     local_file.datasource_config
# #   ]

# #   triggers = {
# #     workspace_id = aws_grafana_workspace.main.id
# #     api_key_name = aws_grafana_workspace_api_key.dashboard_management.key_name
# #     prometheus_workspace_id = aws_prometheus_workspace.main.id
# #     datasource_config = md5(local_file.datasource_config.content)
# #   }

# #   # Configure Prometheus data source (Windows compatible - using file input)
# #   provisioner "local-exec" {
# #     command = "timeout /t 30 /nobreak && curl -X POST -H \"Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}\" -H \"Content-Type: application/json\" --data-binary @${local_file.datasource_config.filename} \"https://${aws_grafana_workspace.main.endpoint}/api/datasources\""
# #   }
# # }

# # # Create dashboard folder (Windows compatible - using file input)
# # resource "null_resource" "create_dashboard_folder" {
# #   depends_on = [
# #     null_resource.configure_grafana_datasource,
# #     local_file.folder_config
# #   ]

# #   triggers = {
# #     workspace_id = aws_grafana_workspace.main.id
# #     folder_title = local.dashboard_folder_config.title
# #     folder_config = md5(local_file.folder_config.content)
# #   }

# #   provisioner "local-exec" {
# #     command = "curl -X POST -H \"Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}\" -H \"Content-Type: application/json\" --data-binary @${local_file.folder_config.filename} \"https://${aws_grafana_workspace.main.endpoint}/api/folders\""
# #   }
# # }

# # # =============================================================================
# # # DASHBOARD TEMPLATE FILES
# # # =============================================================================

# # # Create Kubernetes Cluster Overview Dashboard
# # resource "local_file" "kubernetes_cluster_dashboard" {
# #   filename = "${path.module}/dashboards/kubernetes-cluster-overview.json"
# #   content = jsonencode({
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Cluster Overview - ${var.cluster_name}"
# #       tags     = ["kubernetes", "cluster", "overview", "eks", var.environment]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "Total Nodes"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_node_info{cluster=\"${var.cluster_name}\"})"
# #               legendFormat = "Total Nodes"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               color = {
# #                 mode = "palette-classic"
# #               }
# #               unit = "short"
# #             }
# #           }
# #         },
# #         {
# #           id    = 2
# #           title = "Total Pods"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 6
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_pod_info{cluster=\"${var.cluster_name}\"})"
# #               legendFormat = "Total Pods"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 3
# #           title = "Total Deployments"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 12
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_deployment_labels{cluster=\"${var.cluster_name}\"})"
# #               legendFormat = "Deployments"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 4
# #           title = "Total Services"
# #           type  = "stat"
# #           gridPos = {
# #             h = 4
# #             w = 6
# #             x = 18
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "count(kube_service_info{cluster=\"${var.cluster_name}\"})"
# #               legendFormat = "Services"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 5
# #           title = "Node CPU Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 4
# #           }
# #           targets = [
# #             {
# #               expr         = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\", cluster=\"${var.cluster_name}\"}[5m])) * 100)"
# #               legendFormat = "{{instance}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               color = {
# #                 mode = "palette-classic"
# #               }
# #               unit = "percent"
# #               min  = 0
# #               max  = 100
# #             }
# #           }
# #         },
# #         {
# #           id    = 6
# #           title = "Node Memory Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 4
# #           }
# #           targets = [
# #             {
# #               expr         = "100 - ((node_memory_MemAvailable_bytes{cluster=\"${var.cluster_name}\"} / node_memory_MemTotal_bytes{cluster=\"${var.cluster_name}\"}) * 100)"
# #               legendFormat = "{{instance}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "percent"
# #               min  = 0
# #               max  = 100
# #             }
# #           }
# #         },
# #         {
# #           id    = 7
# #           title = "Pod Status Distribution"
# #           type  = "piechart"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 12
# #           }
# #           targets = [
# #             {
# #               expr         = "sum by (phase) (kube_pod_status_phase{cluster=\"${var.cluster_name}\"})"
# #               legendFormat = "{{phase}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 8
# #           title = "Network Traffic"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 12
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(node_network_receive_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (instance)"
# #               legendFormat = "RX - {{instance}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             },
# #             {
# #               expr         = "sum(rate(node_network_transmit_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (instance)"
# #               legendFormat = "TX - {{instance}}"
# #               refId        = "B"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "binBps"
# #             }
# #           }
# #         }
# #       ]
# #     }
# #     folderId  = local.dashboard_folder_config.uid
# #     overwrite = true
# #   })
# # }

# # # Create Kubernetes Pods Monitoring Dashboard
# # resource "local_file" "kubernetes_pods_dashboard" {
# #   filename = "${path.module}/dashboards/kubernetes-pods-monitoring.json"
# #   content = jsonencode({
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Pods Monitoring - ${var.cluster_name}"
# #       tags     = ["kubernetes", "pods", "containers", var.environment]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "Pod Restarts"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "increase(kube_pod_container_status_restarts_total{cluster=\"${var.cluster_name}\"}[5m])"
# #               legendFormat = "{{namespace}}/{{pod}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 2
# #           title = "Pod CPU Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(container_cpu_usage_seconds_total{container!=\"POD\",container!=\"\",cluster=\"${var.cluster_name}\"}[5m])) by (namespace, pod)"
# #               legendFormat = "{{namespace}}/{{pod}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 3
# #           title = "Pod Memory Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(container_memory_working_set_bytes{container!=\"POD\",container!=\"\",cluster=\"${var.cluster_name}\"}) by (namespace, pod)"
# #               legendFormat = "{{namespace}}/{{pod}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "bytes"
# #             }
# #           }
# #         },
# #         {
# #           id    = 4
# #           title = "Pod Network I/O"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 8
# #           }
# #           targets = [
# #             {
# #               expr         = "sum(rate(container_network_receive_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (namespace, pod)"
# #               legendFormat = "RX - {{namespace}}/{{pod}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             },
# #             {
# #               expr         = "sum(rate(container_network_transmit_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (namespace, pod)"
# #               legendFormat = "TX - {{namespace}}/{{pod}}"
# #               refId        = "B"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "binBps"
# #             }
# #           }
# #         }
# #       ]
# #     }
# #     folderId  = local.dashboard_folder_config.uid
# #     overwrite = true
# #   })
# # }

# # # Create Kubernetes Nodes Monitoring Dashboard
# # resource "local_file" "kubernetes_nodes_dashboard" {
# #   filename = "${path.module}/dashboards/kubernetes-nodes-monitoring.json"
# #   content = jsonencode({
# #     dashboard = {
# #       id       = null
# #       title    = "Kubernetes Nodes Monitoring - ${var.cluster_name}"
# #       tags     = ["kubernetes", "nodes", "infrastructure", var.environment]
# #       timezone = "browser"
# #       refresh  = "30s"
# #       time = {
# #         from = "now-1h"
# #         to   = "now"
# #       }
# #       panels = [
# #         {
# #           id    = 1
# #           title = "Node Status"
# #           type  = "stat"
# #           gridPos = {
# #             h = 6
# #             w = 12
# #             x = 0
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "kube_node_status_condition{condition=\"Ready\",status=\"true\",cluster=\"${var.cluster_name}\"}"
# #               legendFormat = "Ready - {{node}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 2
# #           title = "Node Resource Allocation"
# #           type  = "bargauge"
# #           gridPos = {
# #             h = 6
# #             w = 12
# #             x = 12
# #             y = 0
# #           }
# #           targets = [
# #             {
# #               expr         = "kube_node_status_allocatable{resource=\"cpu\",cluster=\"${var.cluster_name}\"}"
# #               legendFormat = "CPU - {{node}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             },
# #             {
# #               expr         = "kube_node_status_allocatable{resource=\"memory\",cluster=\"${var.cluster_name}\"}"
# #               legendFormat = "Memory - {{node}}"
# #               refId        = "B"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         },
# #         {
# #           id    = 3
# #           title = "Node Disk Usage"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 0
# #             y = 6
# #           }
# #           targets = [
# #             {
# #               expr         = "100 - ((node_filesystem_avail_bytes{fstype!=\"tmpfs\",cluster=\"${var.cluster_name}\"} / node_filesystem_size_bytes{fstype!=\"tmpfs\",cluster=\"${var.cluster_name}\"}) * 100)"
# #               legendFormat = "{{instance}} - {{mountpoint}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #           fieldConfig = {
# #             defaults = {
# #               unit = "percent"
# #               min  = 0
# #               max  = 100
# #             }
# #           }
# #         },
# #         {
# #           id    = 4
# #           title = "Node Load Average"
# #           type  = "timeseries"
# #           gridPos = {
# #             h = 8
# #             w = 12
# #             x = 12
# #             y = 6
# #           }
# #           targets = [
# #             {
# #               expr         = "node_load1{cluster=\"${var.cluster_name}\"}"
# #               legendFormat = "1m - {{instance}}"
# #               refId        = "A"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             },
# #             {
# #               expr         = "node_load5{cluster=\"${var.cluster_name}\"}"
# #               legendFormat = "5m - {{instance}}"
# #               refId        = "B"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             },
# #             {
# #               expr         = "node_load15{cluster=\"${var.cluster_name}\"}"
# #               legendFormat = "15m - {{instance}}"
# #               refId        = "C"
# #               datasource = {
# #                 uid = local.prometheus_datasource_config.uid
# #               }
# #             }
# #           ]
# #         }
# #       ]
# #     }
# #     folderId  = local.dashboard_folder_config.uid
# #     overwrite = true
# #   })
# # }

# # # =============================================================================
# # # IMPORT DASHBOARDS TO GRAFANA (WINDOWS COMPATIBLE)
# # # =============================================================================

# # # Import all dashboards to Grafana (Windows compatible version)
# # resource "null_resource" "import_dashboards" {
# #   depends_on = [
# #     null_resource.create_dashboard_folder,
# #     local_file.kubernetes_cluster_dashboard,
# #     local_file.kubernetes_pods_dashboard,
# #     local_file.kubernetes_nodes_dashboard
# #   ]

# #   triggers = {
# #     dashboard_cluster = md5(local_file.kubernetes_cluster_dashboard.content)
# #     dashboard_pods    = md5(local_file.kubernetes_pods_dashboard.content)
# #     dashboard_nodes   = md5(local_file.kubernetes_nodes_dashboard.content)
# #     workspace_id      = aws_grafana_workspace.main.id
# #   }

# #   # Import cluster overview dashboard (Windows compatible - using --data-binary)
# #   provisioner "local-exec" {
# #     command = "curl -X POST -H \"Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}\" -H \"Content-Type: application/json\" --data-binary @${local_file.kubernetes_cluster_dashboard.filename} \"https://${aws_grafana_workspace.main.endpoint}/api/dashboards/db\""
# #   }

# #   # Import pods dashboard (Windows compatible - using --data-binary)
# #   provisioner "local-exec" {
# #     command = "curl -X POST -H \"Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}\" -H \"Content-Type: application/json\" --data-binary @${local_file.kubernetes_pods_dashboard.filename} \"https://${aws_grafana_workspace.main.endpoint}/api/dashboards/db\""
# #   }

# #   # Import nodes dashboard (Windows compatible - using --data-binary)
# #   provisioner "local-exec" {
# #     command = "curl -X POST -H \"Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}\" -H \"Content-Type: application/json\" --data-binary @${local_file.kubernetes_nodes_dashboard.filename} \"https://${aws_grafana_workspace.main.endpoint}/api/dashboards/db\""
# #   }
# # }

# # # =============================================================================
# # # OUTPUTS
# # # =============================================================================

# # output "grafana_workspace_id" {
# #   description = "ID of the AWS Managed Grafana workspace"
# #   value       = aws_grafana_workspace.main.id
# # }

# # output "grafana_workspace_arn" {
# #   description = "ARN of the AWS Managed Grafana workspace"
# #   value       = aws_grafana_workspace.main.arn
# # }

# # output "grafana_workspace_endpoint" {
# #   description = "Endpoint URL of the AWS Managed Grafana workspace"
# #   value       = aws_grafana_workspace.main.endpoint
# # }

# # output "grafana_dashboard_url" {
# #   description = "URL to access Grafana dashboard"
# #   value       = "https://${aws_grafana_workspace.main.endpoint}"
# # }

# # output "grafana_api_key" {
# #   description = "API key for Grafana workspace (sensitive)"
# #   value       = aws_grafana_workspace_api_key.dashboard_management.key
# #   sensitive   = true
# # }

# # output "grafana_role_arn" {
# #   description = "ARN of the Grafana service IAM role"
# #   value       = aws_iam_role.grafana_role.arn
# # }

# # output "prometheus_datasource_uid" {
# #   description = "UID of the Prometheus data source in Grafana"
# #   value       = local.prometheus_datasource_config.uid
# # }

# # output "grafana_workspace_url" {
# #   description = "Direct URL to access Grafana workspace"
# #   value       = "https://${aws_grafana_workspace.main.endpoint}"
# # }










# # modules/monitoring/grafana.tf
# # This file contains AWS Managed Grafana setup for EKS monitoring
# # Simplified version focused on core monitoring dashboards without complex alerting

# # =============================================================================
# # AWS MANAGED GRAFANA WORKSPACE
# # =============================================================================

# # AWS Managed Grafana Workspace
# # Creates a fully managed Grafana instance for visualizing metrics from AWS Managed Prometheus
# # Benefits:
# # - Fully managed service with automatic scaling and updates
# # - Built-in authentication with AWS SSO
# # - Seamless integration with AWS Managed Prometheus
# # - High availability and automatic backups
# resource "aws_grafana_workspace" "main" {
#   account_access_type      = "CURRENT_ACCOUNT"  # Access only from current AWS account
#   authentication_providers = ["AWS_SSO"]        # Use AWS Single Sign-On for authentication
#   permission_type         = "SERVICE_MANAGED"   # Let AWS manage permissions
#   role_arn               = aws_iam_role.grafana_role.arn
#   name                   = "bsp-eks-grafana-workspace-${var.environment}"
#   description            = "Grafana workspace for EKS cluster monitoring and observability dashboards"
  
#   # Enable Prometheus as a data source
#   data_sources = ["PROMETHEUS"]
  
#   # Grafana version
#   grafana_version = "9.4"
  
#   tags = {
#     Name        = "bsp-grafana-workspace-${var.environment}"
#     Environment = var.environment
#     Purpose     = "EKS-monitoring"
#     Team        = "DevOps"
#     ClusterName = var.cluster_name
#   }
# }

# # =============================================================================
# # IAM ROLES AND POLICIES FOR GRAFANA
# # =============================================================================

# # IAM Role for Grafana Service
# # This role allows AWS Managed Grafana to access Prometheus and other AWS services
# resource "aws_iam_role" "grafana_role" {
#   name = "bsp-grafana-service-role-${var.environment}"

#   # Trust policy allowing Grafana service to assume this role
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "grafana.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = {
#     Name        = "bsp-grafana-service-role-${var.environment}"
#     Environment = var.environment
#     Purpose     = "grafana-service"
#   }
# }

# # IAM Policy for Grafana to access Prometheus and basic AWS services
# # This policy defines what actions Grafana can perform
# resource "aws_iam_policy" "grafana_policy" {
#   name        = "bsp-grafana-access-policy-${var.environment}"
#   description = "Policy for AWS Managed Grafana to access Prometheus and basic AWS services"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         # Permissions for accessing AWS Managed Prometheus
#         Effect = "Allow"
#         Action = [
#           "aps:ListWorkspaces",              # List all Prometheus workspaces
#           "aps:DescribeWorkspace",           # Get details of Prometheus workspaces
#           "aps:QueryMetrics",                # Query metrics from Prometheus
#           "aps:GetLabels",                   # Get metric labels
#           "aps:GetSeries",                   # Get time series data
#           "aps:GetMetricMetadata"            # Get metadata about metrics
#         ]
#         Resource = "*"
#       },
#       {
#         # Basic permissions for accessing EKS information
#         Effect = "Allow"
#         Action = [
#           "eks:DescribeCluster",             # Get EKS cluster details
#           "eks:ListClusters",                # List EKS clusters
#           "ec2:DescribeInstances",           # Get EC2 instance information
#           "ec2:DescribeRegions"              # Get available AWS regions
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # Attach the policy to the Grafana service role
# resource "aws_iam_role_policy_attachment" "grafana_policy_attachment" {
#   role       = aws_iam_role.grafana_role.name
#   policy_arn = aws_iam_policy.grafana_policy.arn
# }

# # =============================================================================
# # GRAFANA API KEY FOR PROGRAMMATIC ACCESS
# # =============================================================================

# # API Key for Grafana workspace
# # This key is used to programmatically configure Grafana data sources and dashboards
# resource "aws_grafana_workspace_api_key" "dashboard_management" {
#   key_name        = "bsp-terraform-dashboard-management-${var.environment}"
#   key_role        = "ADMIN"
#   seconds_to_live = 2592000  # 30 days
#   workspace_id    = aws_grafana_workspace.main.id
# }

# # =============================================================================
# # LOCAL VALUES FOR CONFIGURATION
# # =============================================================================

# locals {
#   # Prometheus data source configuration for Grafana
#   prometheus_datasource_config = {
#     name       = "AWS-Managed-Prometheus-${var.environment}"
#     type       = "prometheus"
#     access     = "proxy"
#     url        = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.main.id}/"
#     is_default = true
#     uid        = "prometheus-${var.environment}"
    
#     json_data = {
#       httpMethod      = "GET"
#       sigV4Auth       = true
#       sigV4AuthType   = "workspace-iam-role"
#       sigV4Region     = data.aws_region.current.name
#       timeInterval    = "30s"
#       queryTimeout    = "300s"
#       prometheusType  = "Prometheus"
#       prometheusVersion = "2.45.0"
#     }
#   }

#   # Dashboard folder configuration
#   dashboard_folder_config = {
#     title = "EKS Monitoring Dashboards"
#     uid   = "eks-monitoring-${var.environment}"
#   }
# }

# # =============================================================================
# # GRAFANA CONFIGURATION VIA API CALLS (WINDOWS COMPATIBLE)
# # =============================================================================

# # Create JSON file for datasource configuration
# resource "local_file" "datasource_config" {
#   filename = "${path.module}/temp/datasource-config.json"
#   content = jsonencode({
#     name       = local.prometheus_datasource_config.name
#     type       = local.prometheus_datasource_config.type
#     access     = local.prometheus_datasource_config.access
#     url        = local.prometheus_datasource_config.url
#     isDefault  = local.prometheus_datasource_config.is_default
#     uid        = local.prometheus_datasource_config.uid
#     jsonData   = local.prometheus_datasource_config.json_data
#   })
# }

# # Create JSON file for folder configuration
# resource "local_file" "folder_config" {
#   filename = "${path.module}/temp/folder-config.json"
#   content = jsonencode({
#     title = local.dashboard_folder_config.title
#     uid   = local.dashboard_folder_config.uid
#   })
# }

# # Configure Prometheus data source using null_resource with API calls
# # This is the workaround since aws_grafana_workspace_configuration doesn't exist
# # WINDOWS COMPATIBLE VERSION - using temporary files instead of inline JSON
# resource "null_resource" "configure_grafana_datasource" {
#   depends_on = [
#     aws_grafana_workspace.main,
#     aws_grafana_workspace_api_key.dashboard_management,
#     local_file.datasource_config
#   ]

#   triggers = {
#     workspace_id = aws_grafana_workspace.main.id
#     api_key_name = aws_grafana_workspace_api_key.dashboard_management.key_name
#     prometheus_workspace_id = aws_prometheus_workspace.main.id
#     datasource_config = md5(local_file.datasource_config.content)
#   }

#   # Configure Prometheus data source (Windows compatible - using PowerShell)
#   provisioner "local-exec" {
#     command = "powershell -Command \"Start-Sleep -Seconds 30; curl -X POST -H 'Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}' -H 'Content-Type: application/json' --data-binary '@${local_file.datasource_config.filename}' 'https://${aws_grafana_workspace.main.endpoint}/api/datasources'\""
#   }
# }

# # Create dashboard folder (Windows compatible - using file input)
# resource "null_resource" "create_dashboard_folder" {
#   depends_on = [
#     null_resource.configure_grafana_datasource,
#     local_file.folder_config
#   ]

#   triggers = {
#     workspace_id = aws_grafana_workspace.main.id
#     folder_title = local.dashboard_folder_config.title
#     folder_config = md5(local_file.folder_config.content)
#   }

#   provisioner "local-exec" {
#     command = "powershell -Command \"curl -X POST -H 'Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}' -H 'Content-Type: application/json' --data-binary '@${local_file.folder_config.filename}' 'https://${aws_grafana_workspace.main.endpoint}/api/folders'\""
#   }
# }

# # =============================================================================
# # DASHBOARD TEMPLATE FILES
# # =============================================================================

# # Create Kubernetes Cluster Overview Dashboard
# resource "local_file" "kubernetes_cluster_dashboard" {
#   filename = "${path.module}/dashboards/kubernetes-cluster-overview.json"
#   content = jsonencode({
#     dashboard = {
#       id       = null
#       title    = "Kubernetes Cluster Overview - ${var.cluster_name}"
#       tags     = ["kubernetes", "cluster", "overview", "eks", var.environment]
#       timezone = "browser"
#       refresh  = "30s"
#       time = {
#         from = "now-1h"
#         to   = "now"
#       }
#       panels = [
#         {
#           id    = 1
#           title = "Total Nodes"
#           type  = "stat"
#           gridPos = {
#             h = 4
#             w = 6
#             x = 0
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "count(kube_node_info{cluster=\"${var.cluster_name}\"})"
#               legendFormat = "Total Nodes"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               color = {
#                 mode = "palette-classic"
#               }
#               unit = "short"
#             }
#           }
#         },
#         {
#           id    = 2
#           title = "Total Pods"
#           type  = "stat"
#           gridPos = {
#             h = 4
#             w = 6
#             x = 6
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "count(kube_pod_info{cluster=\"${var.cluster_name}\"})"
#               legendFormat = "Total Pods"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 3
#           title = "Total Deployments"
#           type  = "stat"
#           gridPos = {
#             h = 4
#             w = 6
#             x = 12
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "count(kube_deployment_labels{cluster=\"${var.cluster_name}\"})"
#               legendFormat = "Deployments"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 4
#           title = "Total Services"
#           type  = "stat"
#           gridPos = {
#             h = 4
#             w = 6
#             x = 18
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "count(kube_service_info{cluster=\"${var.cluster_name}\"})"
#               legendFormat = "Services"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 5
#           title = "Node CPU Usage"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 0
#             y = 4
#           }
#           targets = [
#             {
#               expr         = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\", cluster=\"${var.cluster_name}\"}[5m])) * 100)"
#               legendFormat = "{{instance}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               color = {
#                 mode = "palette-classic"
#               }
#               unit = "percent"
#               min  = 0
#               max  = 100
#             }
#           }
#         },
#         {
#           id    = 6
#           title = "Node Memory Usage"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 12
#             y = 4
#           }
#           targets = [
#             {
#               expr         = "100 - ((node_memory_MemAvailable_bytes{cluster=\"${var.cluster_name}\"} / node_memory_MemTotal_bytes{cluster=\"${var.cluster_name}\"}) * 100)"
#               legendFormat = "{{instance}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               unit = "percent"
#               min  = 0
#               max  = 100
#             }
#           }
#         },
#         {
#           id    = 7
#           title = "Pod Status Distribution"
#           type  = "piechart"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 0
#             y = 12
#           }
#           targets = [
#             {
#               expr         = "sum by (phase) (kube_pod_status_phase{cluster=\"${var.cluster_name}\"})"
#               legendFormat = "{{phase}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 8
#           title = "Network Traffic"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 12
#             y = 12
#           }
#           targets = [
#             {
#               expr         = "sum(rate(node_network_receive_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (instance)"
#               legendFormat = "RX - {{instance}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             },
#             {
#               expr         = "sum(rate(node_network_transmit_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (instance)"
#               legendFormat = "TX - {{instance}}"
#               refId        = "B"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               unit = "binBps"
#             }
#           }
#         }
#       ]
#     }
#     folderId  = local.dashboard_folder_config.uid
#     overwrite = true
#   })
# }

# # Create Kubernetes Pods Monitoring Dashboard
# resource "local_file" "kubernetes_pods_dashboard" {
#   filename = "${path.module}/dashboards/kubernetes-pods-monitoring.json"
#   content = jsonencode({
#     dashboard = {
#       id       = null
#       title    = "Kubernetes Pods Monitoring - ${var.cluster_name}"
#       tags     = ["kubernetes", "pods", "containers", var.environment]
#       timezone = "browser"
#       refresh  = "30s"
#       time = {
#         from = "now-1h"
#         to   = "now"
#       }
#       panels = [
#         {
#           id    = 1
#           title = "Pod Restarts"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 0
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "increase(kube_pod_container_status_restarts_total{cluster=\"${var.cluster_name}\"}[5m])"
#               legendFormat = "{{namespace}}/{{pod}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 2
#           title = "Pod CPU Usage"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 12
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "sum(rate(container_cpu_usage_seconds_total{container!=\"POD\",container!=\"\",cluster=\"${var.cluster_name}\"}[5m])) by (namespace, pod)"
#               legendFormat = "{{namespace}}/{{pod}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 3
#           title = "Pod Memory Usage"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 0
#             y = 8
#           }
#           targets = [
#             {
#               expr         = "sum(container_memory_working_set_bytes{container!=\"POD\",container!=\"\",cluster=\"${var.cluster_name}\"}) by (namespace, pod)"
#               legendFormat = "{{namespace}}/{{pod}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               unit = "bytes"
#             }
#           }
#         },
#         {
#           id    = 4
#           title = "Pod Network I/O"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 12
#             y = 8
#           }
#           targets = [
#             {
#               expr         = "sum(rate(container_network_receive_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (namespace, pod)"
#               legendFormat = "RX - {{namespace}}/{{pod}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             },
#             {
#               expr         = "sum(rate(container_network_transmit_bytes_total{cluster=\"${var.cluster_name}\"}[5m])) by (namespace, pod)"
#               legendFormat = "TX - {{namespace}}/{{pod}}"
#               refId        = "B"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               unit = "binBps"
#             }
#           }
#         }
#       ]
#     }
#     folderId  = local.dashboard_folder_config.uid
#     overwrite = true
#   })
# }

# # Create Kubernetes Nodes Monitoring Dashboard
# resource "local_file" "kubernetes_nodes_dashboard" {
#   filename = "${path.module}/dashboards/kubernetes-nodes-monitoring.json"
#   content = jsonencode({
#     dashboard = {
#       id       = null
#       title    = "Kubernetes Nodes Monitoring - ${var.cluster_name}"
#       tags     = ["kubernetes", "nodes", "infrastructure", var.environment]
#       timezone = "browser"
#       refresh  = "30s"
#       time = {
#         from = "now-1h"
#         to   = "now"
#       }
#       panels = [
#         {
#           id    = 1
#           title = "Node Status"
#           type  = "stat"
#           gridPos = {
#             h = 6
#             w = 12
#             x = 0
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "kube_node_status_condition{condition=\"Ready\",status=\"true\",cluster=\"${var.cluster_name}\"}"
#               legendFormat = "Ready - {{node}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 2
#           title = "Node Resource Allocation"
#           type  = "bargauge"
#           gridPos = {
#             h = 6
#             w = 12
#             x = 12
#             y = 0
#           }
#           targets = [
#             {
#               expr         = "kube_node_status_allocatable{resource=\"cpu\",cluster=\"${var.cluster_name}\"}"
#               legendFormat = "CPU - {{node}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             },
#             {
#               expr         = "kube_node_status_allocatable{resource=\"memory\",cluster=\"${var.cluster_name}\"}"
#               legendFormat = "Memory - {{node}}"
#               refId        = "B"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         },
#         {
#           id    = 3
#           title = "Node Disk Usage"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 0
#             y = 6
#           }
#           targets = [
#             {
#               expr         = "100 - ((node_filesystem_avail_bytes{fstype!=\"tmpfs\",cluster=\"${var.cluster_name}\"} / node_filesystem_size_bytes{fstype!=\"tmpfs\",cluster=\"${var.cluster_name}\"}) * 100)"
#               legendFormat = "{{instance}} - {{mountpoint}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#           fieldConfig = {
#             defaults = {
#               unit = "percent"
#               min  = 0
#               max  = 100
#             }
#           }
#         },
#         {
#           id    = 4
#           title = "Node Load Average"
#           type  = "timeseries"
#           gridPos = {
#             h = 8
#             w = 12
#             x = 12
#             y = 6
#           }
#           targets = [
#             {
#               expr         = "node_load1{cluster=\"${var.cluster_name}\"}"
#               legendFormat = "1m - {{instance}}"
#               refId        = "A"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             },
#             {
#               expr         = "node_load5{cluster=\"${var.cluster_name}\"}"
#               legendFormat = "5m - {{instance}}"
#               refId        = "B"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             },
#             {
#               expr         = "node_load15{cluster=\"${var.cluster_name}\"}"
#               legendFormat = "15m - {{instance}}"
#               refId        = "C"
#               datasource = {
#                 uid = local.prometheus_datasource_config.uid
#               }
#             }
#           ]
#         }
#       ]
#     }
#     folderId  = local.dashboard_folder_config.uid
#     overwrite = true
#   })
# }

# # =============================================================================
# # IMPORT DASHBOARDS TO GRAFANA (WINDOWS COMPATIBLE)
# # =============================================================================

# # Import all dashboards to Grafana (Windows compatible version)
# resource "null_resource" "import_dashboards" {
#   depends_on = [
#     null_resource.create_dashboard_folder,
#     local_file.kubernetes_cluster_dashboard,
#     local_file.kubernetes_pods_dashboard,
#     local_file.kubernetes_nodes_dashboard
#   ]

#   triggers = {
#     dashboard_cluster = md5(local_file.kubernetes_cluster_dashboard.content)
#     dashboard_pods    = md5(local_file.kubernetes_pods_dashboard.content)
#     dashboard_nodes   = md5(local_file.kubernetes_nodes_dashboard.content)
#     workspace_id      = aws_grafana_workspace.main.id
#   }

#   # Import cluster overview dashboard (Windows compatible - using PowerShell)
#   provisioner "local-exec" {
#     command = "powershell -Command \"curl -X POST -H 'Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}' -H 'Content-Type: application/json' --data-binary '@${local_file.kubernetes_cluster_dashboard.filename}' 'https://${aws_grafana_workspace.main.endpoint}/api/dashboards/db'\""
#   }

#   # Import pods dashboard (Windows compatible - using PowerShell)
#   provisioner "local-exec" {
#     command = "powershell -Command \"curl -X POST -H 'Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}' -H 'Content-Type: application/json' --data-binary '@${local_file.kubernetes_pods_dashboard.filename}' 'https://${aws_grafana_workspace.main.endpoint}/api/dashboards/db'\""
#   }

#   # Import nodes dashboard (Windows compatible - using PowerShell)
#   provisioner "local-exec" {
#     command = "powershell -Command \"curl -X POST -H 'Authorization: Bearer ${aws_grafana_workspace_api_key.dashboard_management.key}' -H 'Content-Type: application/json' --data-binary '@${local_file.kubernetes_nodes_dashboard.filename}' 'https://${aws_grafana_workspace.main.endpoint}/api/dashboards/db'\""
#   }
# }

# # =============================================================================
# # OUTPUTS
# # =============================================================================

# output "grafana_workspace_id" {
#   description = "ID of the AWS Managed Grafana workspace"
#   value       = aws_grafana_workspace.main.id
# }

# output "grafana_workspace_arn" {
#   description = "ARN of the AWS Managed Grafana workspace"
#   value       = aws_grafana_workspace.main.arn
# }

# output "grafana_workspace_endpoint" {
#   description = "Endpoint URL of the AWS Managed Grafana workspace"
#   value       = aws_grafana_workspace.main.endpoint
# }

# output "grafana_dashboard_url" {
#   description = "URL to access Grafana dashboard"
#   value       = "https://${aws_grafana_workspace.main.endpoint}"
# }

# output "grafana_api_key" {
#   description = "API key for Grafana workspace (sensitive)"
#   value       = aws_grafana_workspace_api_key.dashboard_management.key
#   sensitive   = true
# }

# output "grafana_role_arn" {
#   description = "ARN of the Grafana service IAM role"
#   value       = aws_iam_role.grafana_role.arn
# }

# output "prometheus_datasource_uid" {
#   description = "UID of the Prometheus data source in Grafana"
#   value       = local.prometheus_datasource_config.uid
# }

# output "grafana_workspace_url" {
#   description = "Direct URL to access Grafana workspace"
#   value       = "https://${aws_grafana_workspace.main.endpoint}"
# }