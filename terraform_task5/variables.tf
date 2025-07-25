variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"

  validation {
    condition     = contains(["us-east-1", "us-east-2", "us-west-1", "us-west-2"], var.aws_region)
    error_message = "Region must be one of: us-east-1, us-east-2, us-west-1, or us-west-2."
  }
}

variable "aws_access_key" {
  description = "Your AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "Your AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "strapi-keypair-rohana-upadhyay"
}

variable "docker_image_tag" {
  description = "Docker image tag (from CI pipeline)"
  type        = string
  default     = "latest"
}

