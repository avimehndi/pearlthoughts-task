provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "task11-strapi-cluster-aviral"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/strapi-aviral-task11"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task-aviral"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "avi-strapi"
    image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-app-aviral:latest"
    essential = true
    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }]
    environment = [
      { name = "APP_KEYS",          value = "1759d33fa760953d6baa88d7c7222713,6fcb8ec873c8c2e49195cfdb2d9a3f6b" },
      { name = "ADMIN_JWT_SECRET", value = "bf95062617220cc40792dd9c977148623df030177f8f506526f0a96231c75fe8" },
      { name = "JWT_SECRET",        value = "5b7d840aac78c4b8649e28e42e5ea590aaae81b46d1481cefa95b2c7a6b79326" },
      { name = "API_TOKEN_SALT",    value = "5086a136d5d081e075f69a0c7d2db355" },
      
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs/aviral-strapi"
      }
    }
  }])
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
  name        = "aviral-tg-blue-11"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = "vpc-06ba36bca6b59f95e"
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "ecs_green" {
  name        = "aviral-tg-green-11"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-06ba36bca6b59f95e"
  health_check {
    path                = "/"
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

resource "aws_lb_listener" "listener-ecs-test" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_green.arn
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "aviral-strapi-ecs-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = "vpc-06ba36bca6b59f95e"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ALB to access ECS task on port 1337"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    security_groups = [ aws_security_group.aviral_alb_sg.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_security_group" "aviral_alb_sg" {
  name        = "aviral-strapi-alb-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = "vpc-06ba36bca6b59f95e"

  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from the internet"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow test listener port"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

resource "aws_codedeploy_app" "strapi_app" {
  name             = "StrapiCodeDeployApp-aviral"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_deployment_group" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "StrapiDeployGroup-dg"
  service_role_arn      = aws_iam_role.codedeploy_ecs_role.arn

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
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
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener-ecs.arn]
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.listener-ecs-test.arn]
      }
      target_group {
        name = aws_lb_target_group.ecs_blue.name
      }
      target_group {
        name = aws_lb_target_group.ecs_green.name
      }
    }
  }
}

resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service-aviral"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }
  network_configuration {
    subnets          =  ["subnet-0f768008c6324831f", "subnet-0cc2ddb32492bcc41"]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_blue.arn   # or green
    container_name   = "avi-strapi"
    container_port   = 1337
  }
  depends_on = [ aws_lb_listener.listener-ecs ]
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
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"

}
resource "aws_iam_role_policy" "codedeploy_ecs_permissions" {
  name = "CodeDeployECSInlinePolicy"
  role = aws_iam_role.codedeploy_ecs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "lambda:InvokeFunction",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "s3:GetObject",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}


