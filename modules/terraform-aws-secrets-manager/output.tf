output "secret_value" {
  value     = var.create_secret_value ? var.secret_value : random_password.this[0].result
  sensitive = true
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}