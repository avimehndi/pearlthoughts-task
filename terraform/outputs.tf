output "alb_dns_name" {
  description = "Public DNS of ALB to access Strapi app"
  value       = aws_lb.alb.dns_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch Dashboard for ECS monitoring"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards/dashboard/Strapi-ECS-Dashboard-aviral-t8"
}