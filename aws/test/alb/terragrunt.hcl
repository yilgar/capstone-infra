include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../modules/terraform-aws-alb"
}

inputs = {
  name               = "${local.common_vars.namespace}-${local.common_vars.environment}-alb"
  load_balancer_type = "application"
  internal           = false

  vpc_id          = dependency.vpc.outputs.vpc_id
  subnets         = dependency.vpc.outputs.public_subnets
  security_groups = [dependency.alb_sg.outputs.security_group_id]

  # Target groups are managed by ecs/fargate via listener rules.
  target_groups = []

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  ]

  enable_deletion_protection = false

  tags = local.common_vars.tags
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "alb_sg" {
  config_path = "../sg/alb"
}
