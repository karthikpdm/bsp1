resource "aws_cloudwatch_metric_alarm" "eks_node_not_ready_alarm" {
  alarm_name          = "${var.project_name}-eks-node-NotReady-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 0

  alarm_description   = "Alarm when any EKS node is in NotReady state"
  treat_missing_data  = "missing"

  alarm_actions = [
    aws_sns_topic.monitoring-group.arn
  ]
  
  metric_query {
    id          = "total_nodes"
    label       = "Total Nodes"
    return_data = false

    metric {
      namespace   = "ContainerInsights"
      metric_name = "cluster_node_count"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ClusterName = "${var.project_name}-eks-cluster-${var.env}"
      }
    }
  }

  metric_query {
    id          = "ready_nodes"
    label       = "Ready Nodes"
    return_data = false

    metric {
      namespace   = "ContainerInsights"
      metric_name = "node_status_condition_ready"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ClusterName = "${var.project_name}-eks-cluster-${var.env}"
      }
    }
  }

  metric_query {
    id          = "not_ready_nodes"
    label       = "NotReady Nodes"
    return_data = true

    expression  = "total_nodes - ready_nodes"
  }
  
  tags = merge(
    { "Name"    = "${var.project_name}-eks-node-NotReady-Alarm-${var.env}" },
    var.map_tagging
  )
}

resource aws_cloudwatch_metric_alarm "eks-node-cpu-utilization" {
  alarm_name          = "${var.project_name}-eks-node-cpu-utilization-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"

  statistic           = "Average"
  unit                = "Percent"
  threshold           = "60"
  alarm_description   = "The Average CPU utilization of all the nodes is above 60% in ${var.env}"
  datapoints_to_alarm = 1
  treat_missing_data = "breaching"

  alarm_actions = [
    aws_sns_topic.monitoring-group.arn
  ]
  dimensions = {
    "ClusterName" = "${var.project_name}-eks-cluster-${var.env}"
  }

  tags = merge(
    { "Name"    = "${var.project_name}-eks-node-cpu-utilization-${var.env}" },
    var.map_tagging
  )
}

resource aws_cloudwatch_metric_alarm "eks-pod-cpu-utilization" {
  alarm_name          = "${var.project_name}-eks-pod-cpu-utilization-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "pod_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"

  statistic           = "Average"
  unit                = "Percent"
  threshold           = "60"
  alarm_description   = "The Average CPU utilization of all the pods is above 60% in ${var.env}"
  datapoints_to_alarm = 1
  treat_missing_data = "breaching"

  alarm_actions = [
    aws_sns_topic.monitoring-group.arn
  ]
  dimensions = {
    "ClusterName" = "${var.project_name}-eks-cluster-${var.env}"
  }

  tags = merge(
    { "Name"    = "${var.project_name}-eks-pod-cpu-utilization-${var.env}" },
    var.map_tagging
  )
}

