include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../../modules/terraform-aws-iam-ecs"
}

inputs = {
  namespace   = local.common_vars.namespace
  environment = local.common_vars.environment

  s3_bucket_arn = dependency.s3.outputs.s3_bucket_arn

  secret_arns = [
    dependency.db_username.outputs.secret_arn,
    dependency.db_password.outputs.secret_arn,
    dependency.s3_bucket_name.outputs.secret_arn,
  ]

  tags = local.common_vars.tags
}

dependency "s3" {
  config_path = "../../s3"
}

dependency "db_username" {
  config_path = "../../secrets-manager/username"
}

dependency "db_password" {
  config_path = "../../secrets-manager/password"
}

dependency "s3_bucket_name" {
  config_path = "../../secrets-manager/s3-bucket-name"
}
