provider "aws" {
  region     = var.region
}

data "aws_vpc" "default" {
  default = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "strapi_log_group" {
  name              = "/ecs/strapi-app-avi"
  retention_in_days = 7
}

# Security Group
resource "aws_security_group" "aviral_sg" {
  name        = "aviral-strapi-alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aviral-strapi-alb-sg"
  }
}

# ALB
resource "aws_lb" "aviral_strapi_alb" {
  name               = "aviral-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.aviral_sg.id]
  subnets            = ["subnet-0c0bb5df2571165a9", "subnet-0cc2ddb32492bcc41"]

  tags = {
    Name = "aviral-strapi-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "aviral_strapi_tg" {
  name         = "aviral-strapi-tg"
  port         = 1337
  protocol     = "HTTP"
  vpc_id       = data.aws_vpc.default.id
  target_type  = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "aviral-strapi-tg"
  }
}

# Listener
resource "aws_lb_listener" "aviral_listener" {
  load_balancer_arn = aws_lb.aviral_strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aviral_strapi_tg.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "aviral_strapi_cluster" {
  name = "aviral-strapi-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "aviral_strapi_task" {
  family                   = "aviral-strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "aviral-strapi"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ]
      environment = [
        { name = "APP_KEYS",          value = "mriGdnuXMw5hhVE5h+90WXd/HFgg/IBAKhavxAaVpNw=" },
        { name = "ADMIN_JWT_SECRET", value = "Ue3phXdalctbFhG/nzlJEyOWp55bpB+0yDmrrOJkUd8=" },
        { name = "JWT_SECRET",        value = "Z7zoAA+ZLE4z5i6P2bWJNG80hDjn+UAAKaXrjOVirgg=" },
        { name = "API_TOKEN_SALT",    value = "OHbq7RyXEpOGgfMpPES1Dw==" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "aviral_strapi_service" {
  name            = "aviral-strapi-service"
  cluster         = aws_ecs_cluster.aviral_strapi_cluster.id
  task_definition = aws_ecs_task_definition.aviral_strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0c0bb5df2571165a9", "subnet-0cc2ddb32492bcc41"]
    assign_public_ip = true
    security_groups  = [aws_security_group.aviral_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.aviral_strapi_tg.arn
    container_name   = "aviral-strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.aviral_listener]
}
