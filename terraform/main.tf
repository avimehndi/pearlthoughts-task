provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

variable "subnet_ids" {
  type = list(string)
  description = "List of subnet IDs"
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
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener_rule" "ecs" {
  listener_arn = var.aws_lb_listener.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_ecs_service" "ecs" {
  name            = "strapi-service-aviral"
  cluster         = var.ecs_cluster_name.id
  task_definition = aws_ecs_task_definition.ecs.arn
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

resource "aws_codedeploy_app" "strapi_app" {
  name             = "StrapiCodeDeployApp-aviral"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_deployment_group" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "StrapiDeployGroup-avi"
  service_role_arn      = aws_iam_role.strapi_codedeploy.arn

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
    service_name = aws_ecs_service.strapi_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.strapi_tg_blue.name
      }
      target_group {
        name = aws_lb_target_group.strapi_tg_green.name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.strapi_listener.arn]
      }
    }
  }
}
resource "aws_iam_role" "strapi_codedeploy" {
  name = "strapi-codedeploy-role1-aviral"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "strapi_codedeploy_attach" {
  role       = aws_iam_role.strapi_codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

