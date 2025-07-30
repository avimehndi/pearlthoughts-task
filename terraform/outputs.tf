output "alb_dns_name" {
  description = "Public DNS of ALB to access Strapi app"
  value       = aws_lb.alb.dns_name
}


output "ecs_service_name" {
  value = aws_ecs_service.strapi_service.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.strapi_cluster.name
}