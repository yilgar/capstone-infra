locals {
  container_definition = {
    name      = var.container_name
    image     = var.container_image
    essential = true

    memory = var.container_memory
    cpu    = var.container_cpu

    portMappings = var.port_mappings

    environment = var.environment
    secrets     = var.secrets

    command = var.command

    mountPoints = var.mount_points

    ulimits = var.ulimits

    logConfiguration = var.log_configuration
  }

  # Remove null values
  container_definition_without_null = {
    for k, v in local.container_definition :
    k => v
    if v != null && v != [] && v != {}
  }
}
