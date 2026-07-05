output "json" {
  description = "JSON encoded container definition"
  value       = jsonencode(local.container_definition_without_null)
}

output "json_map" {
  description = "Container definition as a map"
  value       = local.container_definition_without_null
}
