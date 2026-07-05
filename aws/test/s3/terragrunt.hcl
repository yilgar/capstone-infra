include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/terraform-aws-s3-bucket"
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name        = "capstone-bucket"
}

inputs = {
  bucket = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  
  
  
  # Versioning
  versioning = {
    enabled = true
  }

  # Lifecycle Rules
  lifecycle_rule = [
    {
      id      = "cleanup-old-versions"
      enabled = true

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]
  
  # Block public access - Security
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  tags = local.common_vars.tags
}                              