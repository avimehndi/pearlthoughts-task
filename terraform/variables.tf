variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}
variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "ecs_cluster_name" {
  description = "ECS cluster name (reference)"
  type        = string
  default     = "aviral-strapi-cluster-task11"
}

variable "container_name" {
  description = "Name of the container used in task definition"
  type        = string
  default     = "av-strapi"
}

variable "aws_lb_listener_arn" {
  description = "ARN of the ALB Listener"
  type        = string
}
