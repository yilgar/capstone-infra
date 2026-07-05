resource "aws_appautoscaling_target" "to_target_scaling" {
  count              = var.scaling_enabled ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${var.namespace}-${var.environment}-${var.task_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "target_to_memory" {
  count              = var.scaling_enabled ? 1 : 0
  name               = "target-to-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.to_target_scaling[0].resource_id
  scalable_dimension = aws_appautoscaling_target.to_target_scaling[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.to_target_scaling[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = var.target_memory
  }
}

resource "aws_appautoscaling_policy" "target_to_cpu" {
  count              = var.scaling_enabled ? 1 : 0
  name               = "target-to-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.to_target_scaling[0].resource_id
  scalable_dimension = aws_appautoscaling_target.to_target_scaling[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.to_target_scaling[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
    target_value       = var.target_cpu
  }
}
