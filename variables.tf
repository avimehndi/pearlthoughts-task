variable "region" {
  type = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair"
  type        = string
}

variable "docker_image" {
  description = "Docker image name to pull and run"
  type        = string
}
