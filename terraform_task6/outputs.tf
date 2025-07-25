output "strapi_url" {
  description = "Public URL of the Strapi application"
  value       = aws_lb.aviral_strapi_alb.dns_name
}


#607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-app-aviral
#the ecr image URL