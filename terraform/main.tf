provider "aws" {
  region = "us-east-2"
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "aviral-strapi-cluster2"
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "aviral-strapi-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/aviral-strapi-app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@aviral-strapi-postgres.cbymg2mgkcu2.us-east-2.rds.amazonaws.com:5432/${var.db_name}"
        },
        {
          name  = "APP_KEYS"
          value = "H5mnz8odDwNsrPrHYZMK+w==,vflz6dcxdZtLmb/qr/38bg==,2RQzSRADDruCIWu1qHtkGw==,gwSyUiod2cNkoIifB1wClw=="
        },
        {
          name  = "JWT_SECRET"
          value = "EYw8dnO6uAJgieoP0V2QCA=="
        },
        {
          name  = "API_TOKEN_SALT"
          value = "ntITJUKq7KPLSs3yMDWmWw=="
        },
        {
          name  = "ADMIN_JWT_SECRET"
          value = "EYw8dnO6uAJgieoP0V2QCA=="
        },
        {
          name  = "TRANSFER_TOKEN_SALT"
          value = "6hJTsNusRF6kArOCiUI0aA=="
        },
        {
          name  = "ENCRYPTION_KEY"
          value = "oQQVoC1EbAsvD0UUeGNHDA=="
        },
        
      ]
    }
  ])
}

resource "aws_security_group" "ecs_sg" {
  name        = "aviral-strapi-ecs-sg"
  description = "Allow HTTP from anywhere and Postgres traffic within SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Postgres access"
    from_port   = 5432
    to_port     = 5432
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
    Name = "Aviral-Strapi-ECS-SG"
  }

  
}

# Load Balancer
resource "aws_lb" "alb" {
  name               = "new-strapi-alb-aviral"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets = [
  "subnet-024126fd1eb33ec08", 
  "subnet-03e27b60efa8df9f0"  
]
}
# Create RDS subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "aviral-strapi-db-subnet-group"
  subnet_ids = [
    "subnet-024126fd1eb33ec08", 
    "subnet-03e27b60efa8df9f0"  
  ]
  tags = {
    Name = "strapi-db-subnet-group-avi"
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}


# Target group for ECS tasks
resource "aws_lb_target_group" "tg" {
  name        = "aviral-strapi-tg-new"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/"
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

# Listener to forward HTTP to target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Create RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier             = "aviral-strapi-postgres"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  backup_retention_period = 7

  tags = {
    Name = "AviralStrapiPostgresDB"
  }
}

## ECS Service
resource "aws_ecs_service" "strapi_service" {
  name            = "aviral-strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
    "subnet-024126fd1eb33ec08", 
    "subnet-03e27b60efa8df9f0"  
  ]

    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.listener]
}