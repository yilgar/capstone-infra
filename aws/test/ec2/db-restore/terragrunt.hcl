include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

terraform {
  source = "../../../../modules/terraform-aws-ec2"
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "sg_ec2" {
  config_path = "../../sg/ec2"
}

dependency "s3" {
  config_path = "../../s3"
}

inputs = {
  namespace     = local.common_vars.namespace
  environment   = local.common_vars.environment
  name          = "db-restore"
  instance_type = "t3.micro"

  # Use private subnet for the instance
  subnet_id = dependency.vpc.outputs.private_subnets[0]

  security_group_ids = [
    dependency.sg_ec2.outputs.security_group_id
  ]

  # S3 bucket for database dumps
  s3_bucket_name = dependency.s3.outputs.s3_bucket_id

  # User data to install MySQL client and necessary tools
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    dnf update -y
    
    # Install MySQL client and utilities
    dnf install -y mariadb105 jq
    
    # Install AWS CLI v2 (already included in AL2023)
    # Install Session Manager plugin
    dnf install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Create directory for database dumps
    mkdir -p /opt/db-restore
    chmod 755 /opt/db-restore
    
    echo "EC2 instance setup completed at $(date)" > /var/log/user-data.log
  EOF

  root_volume_size = 20
  root_volume_type = "gp3"

  tags = merge(
    local.common_vars.tags,
    {
      Purpose = "Database Restore Operations"
    }
  )
}
