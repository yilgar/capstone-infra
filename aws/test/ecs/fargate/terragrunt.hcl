include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))

  task_name      = "api"
  container_port = 8000
}

terraform {
  source = "../../../../modules/terraform-aws-ecs-fargate"
}

inputs = {
  namespace   = local.common_vars.namespace
  environment = local.common_vars.environment
  task_name   = local.task_name

  task_cpu      = 256
  task_memory   = 512
  desired_count = 1

  cluster_id   = dependency.cluster.outputs.ecs_cluster_id
  cluster_name = dependency.cluster.outputs.ecs_cluster_name

  service_subnets         = dependency.vpc.outputs.private_subnets
  service_security_groups = [dependency.sg_ecs.outputs.security_group_id]

  vpc_id              = dependency.vpc.outputs.vpc_id
  aws_lb_listener_arn = dependency.alb.outputs.http_tcp_listener_arns[0]
  target_group_name   = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.task_name}-tg"
  host_headers        = ["*"]

  health_check_path     = "/docs"
  health_check_protocol = "HTTP"

  # Both roles managed centrally by iam/roles — fargate module skips creating its own execution role.
  execution_role_arn      = dependency.iam.outputs.execution_role_arn
  iam_execution_role_name = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.task_name}-execution-role"
  task_role_arn           = dependency.iam.outputs.task_role_arn
  secret_arns             = []

  app_container_name  = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.task_name}"
  app_container_image = "${local.common_vars.account_id}.dkr.ecr.${local.common_vars.region}.amazonaws.com/${local.common_vars.namespace}-${local.common_vars.environment}-${local.task_name}:latest"
  app_container_port  = local.container_port

  app_port_mappings = [
    {
      containerPort = local.container_port
      hostPort      = local.container_port
      protocol      = "tcp"
    }
  ]

  # DB credentials injected at container startup from Secrets Manager.
  app_secrets = [
    { name = "DB_USERNAME", valueFrom = dependency.db_username.outputs.secret_arn },
    { name = "DB_PASSWORD", valueFrom = dependency.db_password.outputs.secret_arn },
  ]

  # Environment variables for application configuration
  app_environment = [
    { name = "DB_HOST", value = dependency.rds.outputs.db_instance_address },
    { name = "DB_NAME", value = "capstone" },
    { name = "DB_SSL_ENABLED", value = "false" },
    { name = "SECRET_KEY", value = "change-this-in-production-to-secure-key" },
    { name = "ALGORITHM", value = "HS256" },
    { name = "ACCESS_TOKEN_EXPIRE_MINUTES", value = "1440" },
    # AWS Bedrock configuration
    { name = "BEDROCK_REGION", value = local.common_vars.region },
    { name = "CHAT_MODEL", value = "eu.amazon.nova-lite-v1:0" },
    { name = "EMBEDDING_MODEL", value = "amazon.titan-embed-text-v2:0" },
    # AWS S3 configuration
    { name = "AWS_REGION", value = local.common_vars.region },
    { name = "S3_BUCKET_NAME", value = dependency.s3.outputs.s3_bucket_id },
  ]

  log_region            = local.common_vars.region
  log_retention_in_days = 30

  tags = local.common_vars.tags
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "cluster" {
  config_path = "../cluster"
}

dependency "alb" {
  config_path = "../../alb"
}

dependency "sg_ecs" {
  config_path = "../../sg/ecs"
}

dependency "iam" {
  config_path = "../../iam/roles"
}

dependency "db_username" {
  config_path = "../../secrets-manager/username"
}

dependency "db_password" {
  config_path = "../../secrets-manager/password"
}

dependency "rds" {
  config_path = "../../rds"
}

dependency "s3" {
  config_path = "../../s3"
}
