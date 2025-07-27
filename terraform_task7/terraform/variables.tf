variable "region" {
  description = "AWS Region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task IAM role ARN"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy"
  type        = string
}
