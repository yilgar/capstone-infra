# Terraform AWS ECS Cluster Module

## Example Terragrunt Configuration

- **terragrunt.hcl** (main configuration)
```
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "eu-central-1"
  profile = "sufle-dev"
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
    bucket  = "test-terragrunt-state"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
    profile = "sufle-dev"
  }
}
```

- **common_vars.yaml**
```
namespace: sufle
environment: test

tags:
  Namespace: sufle
  Environment: test
  Terraform: true
```

- **/ecs/cluster/terragrunt.hcl**
```
include {
  path = find_in_parent_folders()
}

locals {
  common_vars        = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name               = "cluster"
  container_insights = "enabled"
  capacity_providers = ["FARGATE"]
}

terraform {
  source = "../../../..//modules/terraform-aws-ecs-cluster"
}

inputs = {
  cluster_name       = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  container_insights = local.container_insights

  default_capacity_provider_strategy = [
    {
      capacity_provider = local.capacity_providers
    }
  ]
  cluster_settings = [
    {
      name  = "containerInsights"
      value = local.container_insights
    }
  ]

  tags = local.common_vars.tags
}
```