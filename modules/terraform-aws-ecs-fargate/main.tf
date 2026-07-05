resource "aws_lb_target_group" "lb_tg" {
  name        = var.target_group_name
  port        = var.app_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags        = var.tags

  health_check {
    protocol = var.health_check_protocol
    path     = var.health_check_path
  }

  stickiness {
    enabled         = var.stickiness_enabled
    cookie_duration = var.stickiness_cookie_duration
    type            = var.stickiness_type
  }
}

resource "aws_lb_listener_rule" "lb_rule" {
  listener_arn = var.aws_lb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "${var.namespace}-${var.environment}-${var.app_container_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

locals {
  app_container_definition = {
    name      = "${var.namespace}-${var.environment}-${var.app_container_name}"
    image     = var.app_container_image
    essential = true

    memory = var.app_container_memory
    cpu    = var.app_container_cpu

    portMappings = var.app_port_mappings

    environment = var.app_environment
    secrets     = var.app_secrets

    command = var.app_command

    mountPoints = var.mount_points

    ulimits = var.app_ulimits

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = var.log_region
        "awslogs-group"         = "${var.namespace}-${var.environment}-${var.app_container_name}"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }

  # Remove null values
  app_container_definition_clean = {
    for k, v in local.app_container_definition :
    k => v
    if v != null && v != [] && v != {}
  }
}


resource "aws_ecs_task_definition" "task" {
  family             = "${var.namespace}-${var.environment}-${var.task_name}"
  execution_role_arn = var.execution_role_arn != "" ? var.execution_role_arn : aws_iam_role.ecs_task_execution_role[0].arn
  task_role_arn      = var.task_role_arn != "" ? var.task_role_arn : null
  network_mode       = "awsvpc"

  cpu    = var.task_cpu
  memory = var.task_memory

  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    local.app_container_definition_clean
  ])

  dynamic "volume" {
    for_each = var.task_volumes
    content {
      name      = volume.value["name"]
      host_path = lookup(volume.value, "host_path", null)
    }
  }

  tags = var.tags
}

resource "aws_ecs_service" "service" {
  name            = "${var.namespace}-${var.environment}-${var.task_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.service_subnets
    security_groups  = var.service_security_groups
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    container_name   = "${var.namespace}-${var.environment}-${var.app_container_name}"
    container_port   = var.app_container_port
  }

  depends_on = [aws_lb_listener_rule.lb_rule]

  tags = var.tags
}
