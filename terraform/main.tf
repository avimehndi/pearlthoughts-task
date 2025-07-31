provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/strapi-task-aviral-task11"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "task11-strapi-cluster-aviral"
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

}

resource "aws_lb" "alb" {
  name               = "aviral-strapi-alb-task11"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets = [
    "subnet-0c0bb5df2571165a9",
    "subnet-0cc2ddb32492bcc41"
  ]
}

resource "aws_lb_target_group" "ecs_blue" {
  name        = "aviral-tg-blue-task11"
  port        = 1337
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/admin"
    protocol            = "HTTP"
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

resource "aws_lb_target_group" "ecs_green" {
  name        = "aviral-tg-green-11"
  port        = 1337
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
  health_check {
    path                = "/admin"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "listener-ecs" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_blue.arn
  }
}

resource "aws_lb_listener_rule" "ecs" {
  listener_arn = aws_lb_listener.listener-ecs.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_blue.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
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
    }]
    environment = [
      { name = "APP_KEYS",          value = "1759d33fa760953d6baa88d7c7222713,6fcb8ec873c8c2e49195cfdb2d9a3f6b" },
      { name = "ADMIN_JWT_SECRET", value = "bf95062617220cc40792dd9c977148623df030177f8f506526f0a96231c75fe8" },
      { name = "JWT_SECRET",        value = "5b7d840aac78c4b8649e28e42e5ea590aaae81b46d1481cefa95b2c7a6b79326" },
      { name = "API_TOKEN_SALT",    value = "5086a136d5d081e075f69a0c7d2db355" },
      {
        name  = "SERVER_ALLOWED_HOSTS"
        value = aws_lb.alb.dns_name
      }
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



resource "aws_ecs_service" "ecs" {
  name            = "strapi-service-aviral"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  enable_execute_command   = true
  enable_ecs_managed_tags  = true
  propagate_tags           = "SERVICE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }
  network_configuration {
    subnets          = var.subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [ aws_lb_listener.listener-ecs, aws_lb_target_group.ecs_blue, aws_lb_target_group.ecs_green ]

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_blue.arn   # or green
    container_name   = "av-strapi"
    container_port   = 1337
  }
}

resource "aws_iam_role" "codedeploy_ecs_role" {
  name = "aviral-CodeDeployECSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS"
}


resource "aws_codedeploy_app" "strapi_app" {
  name             = "StrapiCodeDeployApp-aviral"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_deployment_group" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "StrapiDeployGroup-avi"
  service_role_arn      = aws_iam_role.codedeploy_ecs_role.arn

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }


  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }


  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster.name
    service_name = aws_ecs_service.ecs.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.ecs_blue.name
      }
      target_group {
        name = aws_lb_target_group.ecs_green.name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener-ecs.arn]
      }
    }
  }
}

