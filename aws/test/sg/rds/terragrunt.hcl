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
  name        = "${local.common_vars.namespace}-${local.common_vars.environment}-rds-sg"
  description = "Security group for RDS MySQL instance"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = dependency.ecs_sg.outputs.security_group_id
      description              = "Allow MySQL from ECS tasks"
    },
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = dependency.ec2_sg.outputs.security_group_id
      description              = "Allow MySQL from EC2 DB restore instance"
    }
  ]

  egress_rules = ["all-all"]

  tags = local.common_vars.tags
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "ecs_sg" {
  config_path = "../../sg/ecs"
}

dependency "ec2_sg" {
  config_path = "../../sg/ec2"
}
