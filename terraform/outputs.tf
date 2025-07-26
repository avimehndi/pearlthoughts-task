output "strapi_url" {
  description = "Public URL to access Strapi"
  value       = "http://${aws_lb.aviral_alb.dns_name}"
}

