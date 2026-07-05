#!/bin/bash
set -e

echo "=== Deploying EC2 DB Restore Instance ==="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${YELLOW}Step 1: Deploying EC2 Security Group...${NC}"
cd "$SCRIPT_DIR/../sg/ec2"
terragrunt apply -auto-approve

echo -e "${YELLOW}Step 2: Updating RDS Security Group...${NC}"
cd "$SCRIPT_DIR/../sg/rds"
terragrunt apply -auto-approve

echo -e "${YELLOW}Step 3: Deploying EC2 Instance...${NC}"
cd "$SCRIPT_DIR/db-restore"
terragrunt apply -auto-approve

echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Instance details:"
cd "$SCRIPT_DIR/db-restore"
INSTANCE_ID=$(terragrunt output -raw instance_id)
PRIVATE_IP=$(terragrunt output -raw private_ip)

echo "Instance ID: $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"
echo ""
echo "To connect to the instance:"
echo "  aws ssm start-session --target $INSTANCE_ID --region eu-central-1"
echo ""
echo "Wait 2-3 minutes for the instance to register with SSM before connecting."
