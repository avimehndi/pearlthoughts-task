output "strapi_url" {
  description = "Public URL to access Strapi"
  value       = "http://${aws_lb.aviral_alb_new.dns_name}"
}

