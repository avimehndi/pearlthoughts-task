provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/strapi-task-aviral-task9"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "task9-strapi-cluster-aviral"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "aviral-strapi-ecs-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow container port"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AviralStrapiECSSG"
  }
}

resource "aws_lb" "alb" {
  name               = "aviral-strapi-alb-task9"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets = [
    "subnet-0c0bb5df2571165a9",
    "subnet-0cc2ddb32492bcc41"
  ]
}

resource "aws_lb_target_group" "tg" {
  name        = "aviral-strapi-tg-task9"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
  tags = {
    Name = "StrapiTG-aviral"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "av-strapi"
    image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-app-aviral:latest"
    essential = true
    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
    }]
    environment = [
      { name = "APP_KEYS",          value = "1759d33fa760953d6baa88d7c7222713,6fcb8ec873c8c2e49195cfdb2d9a3f6b" },
      { name = "ADMIN_JWT_SECRET", value = "bf95062617220cc40792dd9c977148623df030177f8f506526f0a96231c75fe8" },
      { name = "JWT_SECRET",        value = "5b7d840aac78c4b8649e28e42e5ea590aaae81b46d1481cefa95b2c7a6b79326" },
      { name = "API_TOKEN_SALT",    value = "5086a136d5d081e075f69a0c7d2db355" },
      { name = "SERVER_ALLOWED_HOSTS", value = "*" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "strapi"
      }
    }
  }])
}

resource "aws_ecs_service" "strapi_service" {
  name            = "aviral-strapi-service-task9"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets = [
      "subnet-0c0bb5df2571165a9",
      "subnet-0cc2ddb32492bcc41"
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "av-strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.listener]
}
