variable "region" {
  default = "us-east-2"  
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of your existing EC2 Key Pair"
  default     = "my-key-aviral"
}
variable "db_username" {}
variable "db_password" {}

variable "image_uri" {
  description = "The full ECR image URI"
  type        = string
}
