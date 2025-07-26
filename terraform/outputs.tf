
output "alb_dns" {
  value = aws_lb.strapi_alb.dns_name
}