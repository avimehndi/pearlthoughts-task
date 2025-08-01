output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "codedeploy_app_name" {
  description = "Name of the CodeDeploy Application"
  value       = aws_codedeploy_app.strapi_app.name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy Deployment Group"
  value       = aws_codedeploy_deployment_group.strapi_deployment_group.deployment_group_name
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.strapi_task.arn
}

output "latest_task_definition" {
  value = aws_ecs_task_definition.strapi_task.arn
}
