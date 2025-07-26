provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for ECS service
resource "aws_security_group" "aviral_sg" {
  name        = "aviral-sg"
  description = "Allow HTTP/Strapi traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_lb" "aviral_alb" {
  name               = "aviral"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    "subnet-0c0bb5df2571165a9", # us-east-2a
    "subnet-0cc2ddb32492bcc41", # us-east-2b
    "subnet-0f768008c6324831f"  # us-east-2c
  ]
  security_groups = [aws_security_group.tohid_ecr_sg.id]
  enable_deletion_protection = false
}



resource "aws_lb_target_group" "aviral_tg" {
  name        = "aviral-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "1337"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.aviral_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aviral_tg.arn
  }
}

resource "aws_ecs_cluster" "aviral_cluster" {
  name = "aviral-cluster"
}

resource "aws_cloudwatch_log_group" "tohid_strapi" {
  name              = "/ecs/aviral-strapi"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_task_execution_role_aviral" {
  name = "ecsTaskExecutionRole-aviral"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role_aviral.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "aviral_task" {
  family                   = "aviral-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_aviral.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role_aviral.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.image_url
      essential = true
      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/aviral-strapi",
          awslogs-region        = "us-east-2",
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = aws_db_instance.aviral_db.address },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = "strapidb" },
        { name = "DATABASE_USERNAME", value = "aviral" },
        { name = "DATABASE_PASSWORD", value = "aviral123" },
        { name = "DATABASE_SSL", value = "false" },

        # Strapi secrets
        { name = "APP_KEYS", value = "468cnhT7DiBFuGxUXVh8tA==,0ijw28sTuKb2Xi2luHX6zQ==,TfN3QRc00kFU3Qtg320QNg==,hHRI+D6KWZ0g5PER1WanWw==" },
        { name = "API_TOKEN_SALT", value = "PmzN60QIfFJBz4tGtWWrDg==" },
        { name = "ADMIN_JWT_SECRET", value = "YBeqRecVoyQg7PJGSLv1hg==" },
        { name = "TRANSFER_TOKEN_SALT", value = "eHnkCSXpzUWOmXQBmb0GgQ==" },
        { name = "ENCRYPTION_KEY", value = "MjiUdTqauYmpqsW3wIlnzg==" }
      ]
    }
  ])
}

resource "aws_ecs_service" "aviral_service" {
  name            = "aviral-service"
  cluster         = aws_ecs_cluster.aviral_cluster.id
  task_definition = aws_ecs_task_definition.aviral_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.aviral_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.aviral_tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.http]
}