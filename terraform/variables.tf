variable "region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  default = "arn:aws:iam::607700977843:role/ecsTaskExecutionRole"
}
