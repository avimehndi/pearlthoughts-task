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

# ENV-LIKE VARIABLES for Strapi

variable "app_keys" {
  description = "APP_KEYS used by Strapi"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "ADMIN_JWT_SECRET for Strapi admin"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT_SECRET for Strapi"
  type        = string
  sensitive   = true
}

variable "api_token_salt" {
  description = "API_TOKEN_SALT for Strapi"
  type        = string
  sensitive   = true
}
