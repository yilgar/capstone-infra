locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.common_vars.region}"
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "capstone-infra-${local.common_vars.account_id}"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "${local.common_vars.region}"
    encrypt = true
  }
}
