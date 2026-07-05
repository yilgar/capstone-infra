include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../../modules/terraform-aws-security-group"
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  name        = "${local.common_vars.namespace}-${local.common_vars.environment}-ec2-db-restore-sg"
  description = "Security group for EC2 instance used for database restore operations"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_rules = []

  egress_rules = ["all-all"]

  tags = local.common_vars.tags
}
