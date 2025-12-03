resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

resource "aws_cloudwatch_log_group" "backend" {
  name = "/ecs/${var.cluster_name}-backend"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "backend" {
  family = "${var.cluster_name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "512"
  memory = "1024"
  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([
    {
      name = "backend"
      image = var.backend_image
      essential = true
      portMappings = [{ containerPort = 8080, hostPort = 8080, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.backend.name
          "awslogs-region" = var.region
          "awslogs-stream-prefix" = "backend"
        }
      }
      environment = []
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name = "${var.cluster_name}-backend"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count = var.backend_desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.subnet_ids
    security_groups = var.security_groups
    assign_public_ip = false
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "/ecs/${var.cluster_name}-frontend"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "frontend" {
  family = "${var.cluster_name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = tostring(var.frontend_cpu)
  memory = tostring(var.frontend_memory)
  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([
    {
      name = "frontend"
      image = var.frontend_image
      essential = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.frontend.name
          "awslogs-region" = var.region
          "awslogs-stream-prefix" = "frontend"
        }
      }
      environment = []
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name = "${var.cluster_name}-frontend"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count = var.frontend_desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.subnet_ids
    security_groups = var.security_groups
    assign_public_ip = false
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200

  dynamic "load_balancer" {
    for_each = contains(keys(var.target_group_arns), "frontend") ? [1] : []
    content {
      target_group_arn = var.target_group_arns["frontend"]
      container_name = "frontend"
      container_port = 80
    }
  }
}

resource "aws_cloudwatch_log_group" "admin" {
  name = "/ecs/${var.cluster_name}-admin"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "admin" {
  family = "${var.cluster_name}-admin"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = tostring(var.admin_cpu)
  memory = tostring(var.admin_memory)
  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([
    {
      name = "admin"
      image = var.admin_image
      essential = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.admin.name
          "awslogs-region" = var.region
          "awslogs-stream-prefix" = "admin"
        }
      }
      environment = []
    }
  ])
}

resource "aws_ecs_service" "admin" {
  name = "${var.cluster_name}-admin"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.admin.arn
  desired_count = var.admin_desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.subnet_ids
    security_groups = var.security_groups
    assign_public_ip = false
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200

  dynamic "load_balancer" {
    for_each = contains(keys(var.target_group_arns), "admin") ? [1] : []
    content {
      target_group_arn = var.target_group_arns["admin"]
      container_name = "admin"
      container_port = 80
    }
  }
}
 
