include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../../modules/terraform-aws-security-group"
}

inputs = {
  name        = "${local.common_vars.namespace}-${local.common_vars.environment}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8000
      to_port                  = 8000
      protocol                 = "tcp"
      source_security_group_id = dependency.alb_sg.outputs.security_group_id
      description              = "Allow traffic from ALB on port 8000"
    }
  ]

  egress_rules = ["all-all"]

  tags = local.common_vars.tags
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "alb_sg" {
  config_path = "../../sg/alb"
}
