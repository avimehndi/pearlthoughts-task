variable "region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
}

variable "db_username" {
  description = "RDS database username"
  default     = "strapi_user"
}

variable "db_password" {
  description = "RDS database password"
  default     = "strapi123"
  sensitive   = true
}

variable "db_name" {
  description = "RDS database name"
  default     = "strapi"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}
