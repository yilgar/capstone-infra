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
  name                = "${local.common_vars.namespace}/${local.common_vars.environment}/rds/master/password"
  description         = "RDS master password for ${local.common_vars.namespace} ${local.common_vars.environment}"
  create_secret_value = false
  length              = 20

  tags = local.common_vars.tags
}
