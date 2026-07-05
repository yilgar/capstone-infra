include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))

  db_name        = "capstone"
  instance_class = "db.t3.micro"
  family         = "mysql8.0"
  engine_version = "8.0"
  engine         = "mysql"
  port           = 3306

  allocated_storage     = 20
  max_allocated_storage = 100
}

terraform {
  source = "../../../modules/terraform-aws-rds"
}

inputs = {
  identifier     = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.db_name}"
  engine         = local.engine
  engine_version = local.engine_version
  family         = local.family
  instance_class = local.instance_class

  major_engine_version = "8.0"

  username = dependency.db_username.outputs.secret_value
  password = dependency.db_password.outputs.secret_value

  port                  = local.port
  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  multi_az            = false
  publicly_accessible = false

  vpc_security_group_ids = [dependency.sg_rds.outputs.security_group_id]
  subnet_ids             = dependency.vpc.outputs.database_subnets
  db_subnet_group_name   = dependency.vpc.outputs.database_subnet_group_name
  create_db_subnet_group = false

  skip_final_snapshot = true
  deletion_protection = false

  tags = local.common_vars.tags
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "sg_rds" {
  config_path = "../sg/rds"
}

dependency "db_username" {
  config_path = "../secrets-manager/username"
}

dependency "db_password" {
  config_path = "../secrets-manager/password"
}
