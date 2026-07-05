# Terraform AWS Application Load Balancer Module

## Example Terragrunt Configuration

- **terragrunt.hcl (main configuration)**

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

- **common-vars.yaml**

```
namespace: sufle
environment: test

tags:
  Namespace: sufle
  Environment: test
  Terraform: true
```

- **/alb/terragrunt.hcl**

```
include {
  path = find_in_parent_folders()
}

locals {
  common_vars     = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name            = "ecs-alb"
}

terraform {
  source = "../../..//modules/terraform-aws-alb"
}

inputs = {
  name                        = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  load_balancer_type          = "application"
  subnets                     = dependency.vpc.outputs.public_subnets
  security_groups             = [dependency.sg_alb_main.outputs.security_group_id]
  enable_deletion_protection  = true

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Bad Request"
        status_code  = "400"
      }
    }
  ]

  tags = local.common_vars.tags
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "sg_alb_main" {
  config_path = "../../security-group/alb/"
}

```

This configuration creates an Application Load Balancer with an HTTP listener. VPC and Security Group must have been created to create an Application Load Balancer.