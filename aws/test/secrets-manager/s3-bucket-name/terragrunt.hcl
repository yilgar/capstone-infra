include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/terraform-aws-secrets-manager"
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

dependency "s3" {
  config_path = "../../s3"
}

inputs = {
  name        = "${local.common_vars.namespace}/${local.common_vars.environment}/s3-bucket-name"
  description = "S3 bucket name for gallery images"
  secret_string = dependency.s3.outputs.s3_bucket_id
  
  tags = local.common_vars.tags
}
