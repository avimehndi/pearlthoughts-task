variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "container_image" {
  description = "Docker image URL for the Strapi application"
  type        = string
}

variable "app_keys" {
  description = "Strapi application keys"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "Strapi admin JWT secret"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Strapi user JWT secret"
  type        = string
  sensitive   = true
}

variable "api_token_salt" {
  description = "Strapi API token salt"
  type        = string
  sensitive   = true
}

variable "task_role_arn" {
  description = "IAM role ARN for the ECS task"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  type        = string
}

# ✅ Add these for DB connection

variable "database_client" {
  description = "Database client type (e.g. postgres)"
  type        = string
  default     = "postgres"
}

variable "database_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "image_uri" {
  description = "Docker image URI"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}
