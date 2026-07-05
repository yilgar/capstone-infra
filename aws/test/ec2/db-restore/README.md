# EC2 Database Restore Instance

Bu EC2 instance, RDS veritabanına MySQL dump dosyalarını restore etmek için kullanılır.

## Özellikler

- **Instance Type**: t3.micro
- **AMI**: Amazon Linux 2023 (otomatik en son sürüm)
- **Network**: Private subnet içinde
- **Access**: AWS Systems Manager (SSM) Session Manager ile
- **Pre-installed Tools**: 
  - MariaDB client (MySQL uyumlu)
  - AWS CLI v2
  - SSM Agent

## Deployment

### 1. Security Group'u Deploy Et

```bash
cd capstone-infra/aws/test/sg/ec2
terragrunt apply
```

### 2. EC2 Instance'ı Deploy Et

```bash
cd capstone-infra/aws/test/ec2/db-restore
terragrunt apply
```

## EC2'ye Bağlanma

Instance private subnet'te olduğu için SSM Session Manager kullanarak bağlanın:

```bash
# Instance ID'yi al
INSTANCE_ID=$(cd capstone-infra/aws/test/ec2/db-restore && terragrunt output -raw instance_id)

# SSM ile bağlan
aws ssm start-session --target $INSTANCE_ID --region eu-central-1
```

## Database Dump Restore İşlemi

### 1. Dump Dosyasını S3'e Yükle

```bash
aws s3 cp CapstoneService/database_dump.sql s3://capstone-test-app-bucket/db-dumps/database_dump.sql
```

### 2. EC2'ye Bağlan ve Dump'ı İndir

```bash
# SSM session içinde
sudo su -
cd /opt/db-restore

# S3'ten dump dosyasını indir
aws s3 cp s3://capstone-test-app-bucket/db-dumps/database_dump.sql .
```

### 3. RDS Bilgilerini Al

```bash
# Local terminalinizde
cd capstone-infra/aws/test/rds
terragrunt output

# RDS endpoint ve credentials'ı not edin
```

### 4. Database'i Restore Et

```bash
# SSM session içinde (EC2'de)
# RDS endpoint'i ve credentials'ı kullanarak

# Önce mevcut database'i temizle (opsiyonel)
mysql -h <RDS_ENDPOINT> -u <USERNAME> -p<PASSWORD> -e "DROP DATABASE IF EXISTS capstone_db; CREATE DATABASE capstone_db;"

# Dump'ı restore et
mysql -h <RDS_ENDPOINT> -u <USERNAME> -p<PASSWORD> capstone_db < /opt/db-restore/database_dump.sql

# Restore'u doğrula
mysql -h <RDS_ENDPOINT> -u <USERNAME> -p<PASSWORD> capstone_db -e "SHOW TABLES;"
```

### Alternatif: Secrets Manager'dan Credentials Al

```bash
# SSM session içinde
SECRET_ARN=$(aws secretsmanager list-secrets --region eu-central-1 --query "SecretList[?contains(Name, 'rds')].ARN" --output text)

# Secret'ı al
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region eu-central-1 --query SecretString --output text | jq -r .

# Veya doğrudan kullan
DB_HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region eu-central-1 --query SecretString --output text | jq -r .host)
DB_USER=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region eu-central-1 --query SecretString --output text | jq -r .username)
DB_PASS=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region eu-central-1 --query SecretString --output text | jq -r .password)

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS capstone_db < /opt/db-restore/database_dump.sql
```

## Temizlik

Instance'ı kullandıktan sonra maliyetten kaçınmak için silebilirsiniz:

```bash
cd capstone-infra/aws/test/ec2/db-restore
terragrunt destroy
```

## Troubleshooting

### SSM Session başlatılamıyor

1. Instance'ın SSM Agent'ının çalıştığından emin olun
2. IAM role'ün `AmazonSSMManagedInstanceCore` policy'sine sahip olduğunu kontrol edin
3. Instance'ın Systems Manager konsolunda "Managed Instances" altında görünmesini bekleyin (2-3 dakika sürebilir)

### MySQL bağlantı hatası

1. RDS security group'unun EC2 security group'undan gelen trafiğe izin verdiğinden emin olun
2. RDS endpoint'in doğru olduğunu kontrol edin
3. Credentials'ın doğru olduğunu kontrol edin

### S3'ten dosya indirilemiyor

1. EC2 IAM role'üne S3 okuma izni ekleyin:

```bash
cd capstone-infra/aws/test/iam/policy
# policy.tf dosyasına S3 read permission ekleyin
```
