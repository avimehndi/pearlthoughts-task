variable "region" {
  default = "us-east-2"  
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "Name of your existing EC2 Key Pair"
  default     = "key2"
}
variable "db_username" {}
variable "db_password" {}

variable "image_uri" {
  description = "The full ECR image URI"
  type        = string
}