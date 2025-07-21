provider "aws" {
  region = var.region
}

# Security Group allowing SSH and HTTP (port 80 -> Strapi on 1337)
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-aviral"
  description = "Allow SSH and HTTP access to Strapi"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP access to Strapi"
    from_port   = 80
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "strapi-sg-aviral"
    }

}

# Load user_data with image injected
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    docker_image = var.docker_image
  }
}

# EC2 instance running Dockerized Strapi
resource "aws_instance" "strapi_ec2" {
  ami                    = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 (for us-east-2)
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = data.template_file.user_data.rendered
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  tags = {
    Name = "strapi-ec2-instance-aviral"
  }
}
