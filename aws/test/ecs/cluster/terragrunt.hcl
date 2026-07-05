include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../../modules/terraform-aws-ecs-cluster"
}

inputs = {
  cluster_name = "${local.common_vars.namespace}-${local.common_vars.environment}"

  cluster_settings = [
    {
      name  = "containerInsights"
      value = "disabled"
    }
  ]

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
  }

  tags = local.common_vars.tags
}
