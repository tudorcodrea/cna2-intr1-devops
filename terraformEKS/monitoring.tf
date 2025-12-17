# CloudWatch Dashboard for Microservices Monitoring

resource "aws_cloudwatch_dashboard" "microservices_dashboard" {
  dashboard_name = "Microservices-Monitoring-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", "product-events-topic", { "stat": "Sum" }],
            [".", "PublishSize", ".", ".", { "stat": "Average" }],
            [".", "NumberOfNotificationsDelivered", ".", ".", { "stat": "Sum" }],
            [".", "NumberOfNotificationsFailed", ".", ".", { "stat": "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "SNS Topic Metrics (product-events-topic)"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "app/microservices-alb/a542f9680c6644518afaf2c799e76c51-255023407", { "stat": "Average" }],
            [".", "UnHealthyHostCount", ".", ".", { "stat": "Average" }],
            [".", "RequestCount", ".", ".", { "stat": "Sum" }],
            [".", "TargetResponseTime", ".", ".", { "stat": "Average" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "stat": "Sum" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "stat": "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "LoadBalancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", "product-service-api", { "stat": "Sum" }],
            [".", "4XXError", ".", ".", { "stat": "Sum" }],
            [".", "5XXError", ".", ".", { "stat": "Sum" }],
            [".", "Latency", ".", ".", { "stat": "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "API Gateway Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", "introspect1Eks", "Namespace", "microservices", { "stat": "Average" }],
            [".", "pod_memory_utilization", ".", ".", ".", ".", { "stat": "Average" }],
            [".", "pod_network_rx_bytes", ".", ".", ".", ".", { "stat": "Sum" }],
            [".", "pod_network_tx_bytes", ".", ".", ".", ".", { "stat": "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "EKS Pod Metrics (microservices namespace)"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", "introspect1Eks", { "stat": "Average" }],
            [".", "node_memory_utilization", ".", ".", { "stat": "Average" }],
            [".", "node_network_rx_bytes", ".", ".", { "stat": "Sum" }],
            [".", "node_network_tx_bytes", ".", ".", { "stat": "Sum" }],
            [".", "node_diskio_read_bytes", ".", ".", { "stat": "Sum" }],
            [".", "node_diskio_write_bytes", ".", ".", { "stat": "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "EKS Node Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "cluster_failed_node_count", "ClusterName", "introspect1Eks", { "stat": "Maximum" }],
            [".", "cluster_node_count", ".", ".", { "stat": "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "EKS Cluster Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          query = "SOURCE '/aws/containerinsights/introspect1Eks/application' | fields @timestamp, @message | filter @message like /product-service/ | sort @timestamp desc | limit 100"
          region = "us-east-1"
          title  = "Application Logs (Product Service)"
        }
      },
    ]
  })
}

# CloudWatch Alarms for Alerts

resource "aws_cloudwatch_metric_alarm" "sns_messages_alarm" {
  alarm_name          = "SNS-Messages-Published-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfMessagesPublished"
  namespace           = "AWS/SNS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarm when more than 10 messages are published to SNS in 5 minutes"
  dimensions = {
    TopicName = "orders-events"
  }
}

resource "aws_cloudwatch_metric_alarm" "elb_unhealthy_hosts_alarm" {
  alarm_name          = "ELB-Unhealthy-Hosts-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alarm when there are unhealthy hosts in the LoadBalancer"
  dimensions = {
    LoadBalancer = "a2c1fcf330e564589a8bfc4b315bee1d-833279991"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_alarm" {
  alarm_name          = "API-Gateway-5XX-Errors-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alarm when there are more than 5 5XX errors in API Gateway in 5 minutes"
  dimensions = {
    ApiName = "product-service-api"
  }
}

resource "aws_cloudwatch_metric_alarm" "elb_high_latency_alarm" {
  alarm_name          = "ELB-High-Latency-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alarm when ELB latency exceeds 1 second"
  dimensions = {
    LoadBalancer = "a2c1fcf330e564589a8bfc4b315bee1d-833279991"
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_failed_nodes_alarm" {
  alarm_name          = "EKS-Failed-Nodes-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Alarm when there are failed nodes in the EKS cluster"
  dimensions = {
    ClusterName = "introspect1Eks"
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_high_node_cpu_alarm" {
  alarm_name          = "EKS-High-Node-CPU-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when node CPU utilization exceeds 80%"
  dimensions = {
    ClusterName = "introspect1Eks"
  }
}