output "alb_dns_name" {
  description = "Public DNS of ALB to access Strapi app"
  value       = aws_lb.alb.dns_name
}

output "cloudwatch_dashboard_url" {
  value = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=StrapiMonitoring"
}