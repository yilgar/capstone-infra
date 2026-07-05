include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../modules/terraform-aws-ecr"
}

inputs = {
  name                 = "${local.common_vars.namespace}-${local.common_vars.environment}-api"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.common_vars.tags
}
