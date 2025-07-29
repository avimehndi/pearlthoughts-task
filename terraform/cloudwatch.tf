resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "Strapi-ECS-Dashboard-aviral-t9"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ],
            [ ".", "MemoryUtilization", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Average",
          title  = "ECS CPU & Memory Utilization",
          region = var.region
        }
      },
      {
        type = "metric",
        x = 0,
        y = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "RunningTaskCount", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period = 300,
          stat   = "Average",
          title  = "ECS Running Task Count",
          region = var.region
        }
      },
      {
        type = "metric",
        x = 0,
        y = 12,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ],
            [ ".", "NetworkTxBytes", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Sum",
          title  = "ECS Network In/Out (Bytes)",
          region = var.region
        }
      }
    ]
  })
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "Strapi-High-CPU-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alarm if CPU exceeds 75% for 10 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
}

# CloudWatch Alarm for High Memory Utilization
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "Strapi-High-Memory-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm if memory usage exceeds 80% for 10 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
}

# Alarm for Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_tasks" {
  alarm_name          = "Strapi-Unhealthy-Targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Triggered when ALB reports unhealthy ECS targets"
  dimensions = {
    LoadBalancer = aws_lb.alb.name
    TargetGroup  = aws_lb_target_group.tg.name
  }
  treat_missing_data = "notBreaching"
}

# Alarm for ALB Latency
resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "Strapi-ALB-High-Latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.5 # seconds
  alarm_description   = "ALB Target response time > 1.5 seconds"
  dimensions = {
    LoadBalancer = aws_lb.alb.name
    TargetGroup  = aws_lb_target_group.tg.name
  }
  treat_missing_data = "notBreaching"
}
