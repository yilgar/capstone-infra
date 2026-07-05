# EC2 Instances

Bu dizin, test ortamı için EC2 instance'larını içerir.

## Mevcut Instance'lar

### db-restore

Database restore işlemleri için kullanılan t3.micro instance.

**Özellikler:**
- Private subnet içinde
- SSM Session Manager ile erişim
- MySQL client pre-installed
- S3 ve Secrets Manager erişimi

**Deployment:**

```bash
# Otomatik deployment
./deploy-db-restore.sh

# Manuel deployment
cd sg/ec2 && terragrunt apply
cd ../sg/rds && terragrunt apply
cd ../ec2/db-restore && terragrunt apply
```

**Kullanım:**

Detaylı kullanım için [db-restore/README.md](./db-restore/README.md) dosyasına bakın.

## Genel Notlar

- Tüm EC2 instance'lar private subnet'te deploy edilir
- SSM Session Manager kullanılarak erişilir (SSH key gerekmez)
- IAM role'ler otomatik olarak oluşturulur
- Security group'lar otomatik olarak yapılandırılır
