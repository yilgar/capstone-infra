variable "container_name" {
  type        = string
  description = "The name of the container"
}

variable "container_image" {
  type        = string
  description = "The image used to start the container"
}

variable "container_memory" {
  type        = number
  description = "The amount of memory (in MiB) to allow the container to use"
  default     = null
}

variable "container_cpu" {
  type        = number
  description = "The number of cpu units to reserve for the container"
  default     = 0
}

variable "environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container"
  default     = []
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets to pass to the container"
  default     = []
}

variable "port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  description = "The port mappings to configure for the container"
  default     = []
}

variable "ulimits" {
  type = list(object({
    name      = string
    softLimit = number
    hardLimit = number
  }))
  description = "The ulimits to configure for the container"
  default     = []
}

variable "command" {
  type        = list(string)
  description = "The command to run in the container"
  default     = []
}

variable "mount_points" {
  type        = list(map(string))
  description = "The mount points for data volumes in the container"
  default     = []
}

variable "log_configuration" {
  type = object({
    logDriver = string
    options   = map(string)
  })
  description = "The log configuration for the container"
  default     = null
}
