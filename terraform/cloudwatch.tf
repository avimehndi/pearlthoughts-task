# CloudWatch Dashboard for ECS Fargate Strapi Service
resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "Strapi-ECS-Dashboard-aviral"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ],
            [ ".", "MemoryUtilization", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Average",
          region = "us-east-2",
          title  = "ECS CPU & Memory Utilization"
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "RunningTaskCount", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period = 300,
          stat   = "Average",
          region = "us-east-2",
          title  = "ECS Running Task Count"
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 12,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "NetworkBytesIn", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ],
            [ ".", "NetworkBytesOut", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Sum",
          region = "us-east-2",
          title  = "ECS Network In/Out"
        }
      }
    ]
  })
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "Strapi-High-CPU-Alarm-aviral"
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
  alarm_name          = "Strapi-High-Memory-Alarm-aviral"
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