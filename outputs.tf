output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.strapi_ec2.public_ip
}

output "access_url" {
  description = "URL to access Strapi"
  value       = "http://${aws_instance.strapi_ec2.public_ip}"
}
