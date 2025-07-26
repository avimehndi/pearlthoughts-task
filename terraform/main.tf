provider "aws" {
  region = "us-east-2"
}


resource "aws_security_group" "aviral_security_group" {
  name        = "avi-sg"
  description = "Allow HTTP/Strapi traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster-aviral"
}

# Create ECR Repository
resource "aws_ecr_repository" "strapi_repo" {
  name = "strapi-app-aviral"
}

# RDS PostgreSQL (Free Tier)
resource "aws_db_instance" "strapi_db_aviral" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14"
  instance_class       = "db.t3.micro"
  db_name              = "strapidb"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.aviral_security_group.id]
}

# IAM Role (Pre-existing, use ARN provided)

data "aws_iam_role" "task_exec_role" {
  name = "strapi-task-execution-role-aviral"
}

data "aws_iam_role" "task_role" {
  name = "strapi-task-role-aviral"
}


# ECS Task Definition
resource "aws_ecs_task_definition" "strapi_task_aviral" {
  family                   = "strapi-task-aviral"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.task_exec_role.arn
  task_role_arn            = data.aws_iam_role.task_exec_role.arn

  container_definitions = jsonencode([
    {
      name  = "strapi-aviral"
      image = "${aws_ecr_repository.strapi_repo.repository_url}:latest"
      image = var.image_uri

      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ]
      environment = [
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = aws_db_instance.strapi_db.address },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = "strapidb" },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "strapi_service_aviral" {
  name            = "strapi-service-aviral"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task_aviral.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.aviral_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_target_group.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.strapi_listener]
}

# Data source for default subnets
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Application Load Balancer
resource "aws_lb" "strapi_alb_aviral" {
  name               = "strapi-alb-aviral"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.aviral_security_group.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "strapi_tg_aviral" {
  name     = "strapi-tg-aviral"
  port     = 1337
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "strapi_listener_avi" {
  load_balancer_arn = aws_lb.strapi_alb_aviral.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg_aviral.arn
  }
}

# Output the public ALB URL
output "alb_url" {
  value = aws_lb.strapi_alb_aviral.dns_name
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

