 

resource "aws_lb" "alb" {
  name = "${var.name}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = var.security_group_ids
  subnets = var.public_subnet_ids
  enable_deletion_protection = false
  tags = { Name = "${var.name}-alb" }
}

# Create listeners and rules as per target_groups map (expects map like { backend = { port=80, tg_name="..." }, ... })
resource "aws_lb_target_group" "tgs" {
  for_each = var.target_groups
  name = each.value.tg_name
  port = each.value.port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    path = each.value.health_path
    protocol = "HTTP"
    matcher = "200-399"
  }
}

# HTTP listener forwards to the frontend target group if present
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = try(aws_lb_target_group.tgs["frontend"].arn, values(aws_lb_target_group.tgs)[0].arn)
  }
}

# Optional listener rules: route /api to backend and /admin to admin TG if they exist
resource "aws_lb_listener_rule" "backend_api" {
  count = contains(keys(var.target_groups), "backend") ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tgs["backend"].arn
  }
  condition {
    path_pattern {
      values = ["/api/*", "/api"]
    }
  }
}

resource "aws_lb_listener_rule" "admin" {
  count = contains(keys(var.target_groups), "admin") ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tgs["admin"].arn
  }
  condition {
    path_pattern {
      values = ["/admin/*", "/admin"]
    }
  }
}

 

