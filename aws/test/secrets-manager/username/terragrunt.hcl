include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../../modules/terraform-aws-secrets-manager"
}

inputs = {
  name                = "${local.common_vars.namespace}/${local.common_vars.environment}/rds/master/username"
  description         = "RDS master username for ${local.common_vars.namespace} ${local.common_vars.environment}"
  create_secret_value = true
  secret_value        = "capstone_admin"

  tags = local.common_vars.tags
}
