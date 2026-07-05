#!/bin/bash
# This script should be run on the EC2 instance via SSM session
# It automates the database restore process

set -e

echo "=== Database Restore Script ==="

# Configuration
REGION="eu-central-1"
DB_NAME="capstone_db"
DUMP_DIR="/opt/db-restore"
DUMP_FILE="database_dump.sql"

# Get S3 bucket name from tags or environment
S3_BUCKET=$(aws ec2 describe-tags --region $REGION \
  --filters "Name=resource-id,Values=$(ec2-metadata --instance-id | cut -d ' ' -f 2)" \
  "Name=key,Values=S3Bucket" \
  --query 'Tags[0].Value' --output text 2>/dev/null || echo "")

if [ -z "$S3_BUCKET" ]; then
  echo "S3 bucket not found in instance tags. Please provide it:"
  read -p "S3 Bucket Name: " S3_BUCKET
fi

# Get RDS credentials from Secrets Manager
echo "Fetching RDS credentials from Secrets Manager..."
SECRET_ARN=$(aws secretsmanager list-secrets --region $REGION \
  --query "SecretList[?contains(Name, 'rds')].ARN" --output text | head -n1)

if [ -z "$SECRET_ARN" ]; then
  echo "Error: Could not find RDS secret in Secrets Manager"
  exit 1
fi

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region $REGION --query SecretString --output text)

DB_HOST=$(echo $SECRET_JSON | jq -r .host)
DB_USER=$(echo $SECRET_JSON | jq -r .username)
DB_PASS=$(echo $SECRET_JSON | jq -r .password)
DB_PORT=$(echo $SECRET_JSON | jq -r .port // "3306")

echo "Database Host: $DB_HOST"
echo "Database User: $DB_USER"
echo "Database Port: $DB_PORT"

# Download dump file from S3
echo ""
echo "Downloading database dump from S3..."
cd $DUMP_DIR

if [ ! -f "$DUMP_FILE" ]; then
  aws s3 cp "s3://${S3_BUCKET}/db-dumps/${DUMP_FILE}" . || {
    echo "Error: Could not download dump file from S3"
    echo "Please upload the dump file first:"
    echo "  aws s3 cp /path/to/database_dump.sql s3://${S3_BUCKET}/db-dumps/"
    exit 1
  }
fi

echo "Dump file downloaded successfully"

# Test database connection
echo ""
echo "Testing database connection..."
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -e "SELECT 1" > /dev/null 2>&1 || {
  echo "Error: Could not connect to database"
  exit 1
}
echo "Database connection successful"

# Backup existing database (optional)
echo ""
read -p "Do you want to backup the existing database before restore? (y/n): " BACKUP_CHOICE
if [ "$BACKUP_CHOICE" = "y" ]; then
  BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
  echo "Creating backup: $BACKUP_FILE"
  mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME > "$DUMP_DIR/$BACKUP_FILE" || {
    echo "Warning: Backup failed, but continuing..."
  }
fi

# Drop and recreate database
echo ""
read -p "This will DROP and recreate the database. Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Restore cancelled"
  exit 0
fi

echo "Dropping and recreating database..."
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

# Restore database
echo ""
echo "Restoring database from dump file..."
echo "This may take several minutes..."

mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME < "$DUMP_DIR/$DUMP_FILE" || {
  echo "Error: Database restore failed"
  exit 1
}

# Verify restore
echo ""
echo "Verifying restore..."
TABLE_COUNT=$(mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SHOW TABLES" | wc -l)
echo "Number of tables: $((TABLE_COUNT - 1))"

echo ""
echo "=== Database Restore Complete ==="
echo ""
echo "Tables in database:"
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SHOW TABLES"
