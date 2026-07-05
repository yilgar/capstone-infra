# Capstone Infrastructure

Terragrunt-based infrastructure as code for the Capstone healthcare application.

## Architecture

- **VPC**: Isolated network with public/private/database subnets across 2 AZs
- **RDS**: MySQL 8.0 database in private subnets
- **ECS Fargate**: Containerized backend API service
- **ALB**: Application Load Balancer for traffic distribution
- **ECR**: Docker image registry
- **S3**: Asset storage
- **Secrets Manager**: Secure credential storage
- **EC2**: Utility instances for database operations (optional)

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terragrunt** installed (`brew install terragrunt` on macOS)
3. **Terraform** installed (Terragrunt will download if needed)
4. **AWS Account** with appropriate permissions

## Project Structure

```
capstone-infra/
├── aws/
│   └── test/                    # Test environment
│       ├── root.hcl             # Root configuration
│       ├── common_vars.yaml     # Environment variables
│       ├── vpc/                 # VPC module
│       ├── sg/                  # Security groups
│       │   ├── alb/
│       │   ├── ecs/
│       │   └── rds/
│       ├── secrets-manager/     # Secrets
│       │   ├── username/
│       │   └── password/
│       ├── rds/                 # MySQL database
│       ├── s3/                  # Storage bucket
│       ├── ecr/                 # Container registry
│       ├── iam/                 # IAM roles
│       │   └── roles/
│       ├── ec2/                 # EC2 instances (optional)
│       │   └── db-restore/      # Database restore instance
│       ├── alb/                 # Load balancer
│       └── ecs/                 # ECS resources
│           ├── cluster/
│           └── fargate/
└── modules/                     # Terraform modules
    ├── terraform-aws-vpc/
    ├── terraform-aws-rds/
    ├── terraform-aws-ecs-fargate/
    └── ...
```

## Configuration

Edit `aws/test/common_vars.yaml` to customize:

```yaml
account_id: "YOUR_ACCOUNT_ID"
namespace: capstone
environment: test
region: eu-central-1

tags:
  Namespace: capstone
  Environment: test
  Terraform: true
```

## Deployment

### Full Deployment

Deploy all infrastructure in the correct order:

```bash
./deploy.sh
```

This will create:
1. VPC and networking
2. Security groups
3. Secrets Manager secrets
4. RDS MySQL database
5. S3 bucket
6. ECR repository
7. IAM roles
8. Application Load Balancer
9. ECS cluster
10. ECS Fargate service

### Individual Module Deployment

Deploy a specific module:

```bash
cd aws/test/<module-path>
terragrunt apply
```

Example:
```bash
cd aws/test/vpc
terragrunt apply
```

### View Plan

Preview changes without applying:

```bash
cd aws/test/<module-path>
terragrunt plan
```

## Backend State

Terraform state is stored in S3:
- **Bucket**: `capstone-infra`
- **Region**: `eu-central-1`
- **Encryption**: Enabled
- **Path**: `aws/test/<module>/terraform.tfstate`

The S3 bucket must exist before deployment. Create it manually:

```bash
aws s3 mb s3://capstone-infra --region eu-central-1
aws s3api put-bucket-versioning \
  --bucket capstone-infra \
  --versioning-configuration Status=Enabled
```

## Application Deployment

After infrastructure is deployed:

### 1. Build and Push Docker Image

```bash
# Get ECR login
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com

# Build image
cd CapstoneService
docker build -t capstone-test-api .

# Tag image
docker tag capstone-test-api:latest \
  YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/capstone-test-api:latest

# Push image
docker push YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/capstone-test-api:latest
```

### 2. Update ECS Service

The ECS service will automatically pull the new image and restart tasks.

### 3. Access Application

Get the ALB DNS name:

```bash
cd aws/test/alb
terragrunt output lb_dns_name
```

Access the API at: `http://<alb-dns-name>/docs`

## Database Access

### Get RDS Endpoint

```bash
cd aws/test/rds
terragrunt output db_instance_endpoint
```

### Get Database Credentials

```bash
# Username
aws secretsmanager get-secret-value \
  --secret-id capstone/test/rds/master/username \
  --query SecretString --output text

# Password
aws secretsmanager get-secret-value \
  --secret-id capstone/test/rds/master/password \
  --query SecretString --output text
```

### Database Restore from Dump

To restore a database dump to RDS, use the EC2 db-restore instance:

```bash
# 1. Deploy the EC2 instance
cd aws/test/ec2
./deploy-db-restore.sh

# 2. Upload dump file to S3
aws s3 cp CapstoneService/database_dump.sql \
  s3://capstone-test-app-bucket/db-dumps/database_dump.sql

# 3. Connect to EC2 via SSM
INSTANCE_ID=$(cd db-restore && terragrunt output -raw instance_id)
aws ssm start-session --target $INSTANCE_ID --region eu-central-1

# 4. Run restore script on EC2
sudo bash /opt/db-restore/restore-database.sh
```

For detailed instructions, see [aws/test/ec2/db-restore/README.md](aws/test/ec2/db-restore/README.md)

### Connect via Bastion (if needed)

The RDS instance is in private subnets. To connect:

1. Use the EC2 db-restore instance (recommended)
2. Create a bastion host in a public subnet
3. Use SSH tunneling to access RDS
4. Or use AWS Systems Manager Session Manager

## Outputs

Key outputs from the infrastructure:

```bash
# ALB DNS
cd aws/test/alb && terragrunt output lb_dns_name

# RDS Endpoint
cd aws/test/rds && terragrunt output db_instance_endpoint

# ECR Repository URL
cd aws/test/ecr && terragrunt output repository_url

# VPC ID
cd aws/test/vpc && terragrunt output vpc_id
```

## Destruction

Destroy all infrastructure:

```bash
./destroy.sh
```

**WARNING**: This will permanently delete all resources including the database!

## Troubleshooting

### Dependency Errors

If you encounter dependency errors, deploy modules in order:

```bash
# 1. VPC first
cd aws/test/vpc && terragrunt apply

# 2. Security groups
cd aws/test/sg/alb && terragrunt apply
cd aws/test/sg/ecs && terragrunt apply
cd aws/test/sg/rds && terragrunt apply

# 3. Continue with other modules...
```

### State Lock Issues

If state is locked:

```bash
cd aws/test/<module>
terragrunt force-unlock <lock-id>
```

### Module Not Found

Ensure you're in the correct directory and the module source path is correct in `terragrunt.hcl`.

## Security Notes

- RDS is in private subnets (no public access)
- Secrets are stored in AWS Secrets Manager
- Security groups follow least privilege principle
- S3 bucket blocks public access
- IAM roles use minimal required permissions

## Cost Optimization

Test environment uses minimal resources:
- RDS: `db.t4g.micro`
- ECS: 256 CPU / 512 MB memory
- Single NAT Gateway
- No Multi-AZ for RDS

For production, increase:
- RDS instance size
- ECS task resources
- Enable Multi-AZ
- Add auto-scaling

## Support

For issues or questions, contact the DevOps team.
# capstone-infra
