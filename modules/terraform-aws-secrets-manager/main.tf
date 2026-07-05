resource "random_password" "this" {
  count   = var.create_secret_value ? 0 : 1
  length  = var.length
  special = true
  # MySQL password requirements: at least 1 uppercase, 1 lowercase, 1 digit, 1 special
  # Avoid problematic characters: @, ", ', /, \, space
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "aws_secretsmanager_secret" "this" {
  name        = var.name
  description = var.description

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.create_secret_value ? var.secret_value : random_password.this[0].result

  lifecycle {
    create_before_destroy = true
  }
}
